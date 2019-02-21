require 'rubygems'
require 'yaml'
require 'authorizenet'
require 'securerandom'

class ReservationsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper

  before_action :login_required, :except => [:create, :get_on_wait_list]
  before_action :load_user_if_logged_in, :only => [:create, :get_on_wait_list]
  # ssl_required :complete
  # ssl_allowed :create
  include AuthorizeNet::API

  def student_conductor_terms
    render :layout => false
  end

  def index
    if @user.present?
      @reservations = Reservation.where(user_id: @user.id)
    else
      @reservation = Reservation.all
    end
  end

  def show
  end

  def create
    @reservation_requests = []
    @reservation_price = nil
    @wait_list_id = nil
    @cash_reservations_allowed = true
    # is someone coming from an open wait list spot's "purchase your ticket" jump?
    if params[:wait_list_id].present?
      # binding.pry
      wlr = WaitListReservation.where("id = ? AND spot_opened_at IS NOT NULL AND spot_opened_at > ?",
                                  params[:wait_list_id], Setting.earliest_valid_wait_list_opening
                                ).first
      if !wlr.present?
        flash[:error] = "Your request off the wait list was not allowed. Please contact the system administrator."
        redirect_to :action => "my_wait_list_reservations"
        return
      else
        @reservation_requests = []
        @reservation_requests << [wlr.bus, 1]
        if !wlr.bus.cash_reservations_allowed?
          @cash_reservations_allowed = false
        end
        @reservation_price = wlr.bus.to_m
        @wait_list_id = params[:wait_list_id]
        session[:reservation_details] = @reservation_requests
        session[:reservation_price] = @reservation_price
        session[:cash_reservations_allowed] = @cash_reservations_allowed
        session[:wait_list_id] = @wait_list_id
      end

    # inbound from the schedule page
    elsif params[:new_request].present?
      # binding.pry
      @reservation_requests, @reservation_price, @cash_reservations_allowed = parse_schedule_selections(params)
      session[:reservation_details] = @reservation_requests
      session[:reservation_price] = @reservation_price
      session[:cash_reservations_allowed] = @cash_reservations_allowed
      session[:wait_list_id] = nil

    # someone was reserving a spot off the wait list, then jumped to another page
    # like editing a stored address, and is now back...
    elsif session[:wait_list_id].present?
      # binding.pry
      @reservation_requests = session[:reservation_details]
      # @reservation_price = session[:reservation_price]
      @reservation_price = Money.new(session[:reservation_price]["fractional"])
      @cash_reservations_allowed = session[:cash_reservations_allowed]
      @wait_list_id = session[:wait_list_id]

    # if we're not coming from the schedule page, and we already
    # have reservation request details for the session
    #
    # in other words, somebody created reservation request details but
    # then needed to go log in or sign up
    elsif session[:reservation_details].present?
      # binding.pry
      @reservation_requests = session[:reservation_details]
      # @reservation_price = session[:reservation_price]
      @reservation_price = Money.new(session[:reservation_price]["fractional"])
      @cash_reservations_allowed = session[:cash_reservations_allowed]
    else
      # something went seriously wrong, we have no idea why the user is here! ;)
      # raise
      flash.now[:error] = "mistaken action!"
      # redirect_to :action => "get_on_wait_list"
      return
    end

    if @reservation_requests.empty?
      flash[:error] = "Please select one or more tickets to reserve before continuing"
      redirect_to :controller => "index", :action => "index"
      return
    end

    if !request.ssl?
      # url = "https://" + request.host + request.request_uri
      url = request.url
      #redirect_to url
      #return
    end

    if @user.nil?
      flash[:error] = "Please log in or verify your student credentials before continuing with your reservation"
      # store_location
      redirect_to :controller => "user", :action => "login"
      return
    else
      render
      return
    end
  end

  def complete
    # gathering the yay / nay on conductor wishes
    # forcing user back if they checked but did not give phone number
    # binding.pry
    @conductor_wish = false
    @contact_phone = nil
    if params[:conductor] == "yes"
      @conductor_wish = true
      if params[:contact_phone].empty?
        @reservation_requests = session[:reservation_details]
        # @reservation_price = session[:reservation_price]
        @reservation_price = Money.new(session[:reservation_price]["fractional"])
        @wait_list_id = session[:wait_list_id]
        flash[:error] = "Please both check the box AND provide your contact phone number if you would like to be considered for the conductor position"
        redirect_to :action => "create"
        return
      else
        @contact_phone = params[:contact_phone]
      end
    end

    # managing the three possible payment method submissions
    if !params[:pay_by_cash].nil? # paying by cash / check
      error_msg, reservation = process_cash(@user, @conductor_wish, @contact_phone, session[:reservation_details], session[:reservation_price], session[:wait_list_id])
      if error_msg.nil?
        flash[:success] = "Thank you for making a reservation with #{Setting::NAME}!\nYou will receive an e-mail confirmation shortly. Make sure to submit your cash/check payment to #{reservation.earliest_session.cash_reservations_information}"
        redirect_to :action => "my_reservations"
        return
      else
        flash[:error] = error_msg
        redirect_to :action => "create"
      end
    elsif !params[:new_cc_submit].nil? # paying with a newly entered cc
      error_msg, reservation = process_cc(@user, @conductor_wish, @contact_phone,
                                          params[:new_cc],
                                          session[:reservation_details],
                                          session[:reservation_price],
                                          session[:wait_list_id])
      if error_msg.nil?
        flash[:success] = "Thank you for making a reservation with #{Setting::NAME}!\nYou will receive an e-mail confirmation shortly."
        redirect_to :action => "my_reservations"
        return
      else
        flash[:error] = error_msg
        redirect_to :action => "create"
      end
    else # paying with a stored set of payment information
      spa = StoredPaymentAddress.where("id = ? AND user_id = ?", params[:stored_payment_set], @user.id).first
      if spa.nil?
        flash[:error] = "Please select the stored payment information to use"
        redirect_to :action => "create"
        return
      else
        cc_info = Hash.new
        cc_info[:card_number] = params["card_number_"+spa.id.to_s]
        cc_info[:expiration_month] = params["expiration_month_"+spa.id.to_s]
        cc_info[:expiration_year] = params["expiration_year_"+spa.id.to_s]
        cc_info[:name_on_card] = spa.name_on_card
        cc_info[:address_one] = spa.address_one
        cc_info[:city] = spa.city
        cc_info[:state] = spa.state
        cc_info[:zip] = spa.zip
      end

      error_msg, reservation = process_cc(@user, @conductor_wish, @contact_phone,
                                cc_info, session[:reservation_details],
                                session[:reservation_price], session[:wait_list_id])
      if error_msg.nil?
        flash[:success] = "Thank you for making a reservation with #{Setting::NAME}!\nYou will receive an e-mail confirmation shortly."
        redirect_to :action => "my_reservations"
        return
      else
        flash[:error] = error_msg
        redirect_to :action => "create"
        return
      end
    end
  end

  def complete_with_selected
    @charge_amount = session[:reservation_price]['fractional'].to_i
    charge = Stripe::Charge.create({
        amount: @charge_amount, 
        currency: 'usd',
        customer: current_user.stored_stripes[0]['customer_id'] # Previously stored, then retrieved
    })
    r = reserve_tickets(Reservation::PD_CREDIT, @user, @conductor_wish, @contact_phone,
        session[:reservation_details], charge['id'],
        session[:reservation_price], session[:wait_list_id])

        redirect_to :action => "my_reservations",
                    notice: "Thank you for making a reservation with #{Setting::NAME}!\nYou will receive an e-mail confirmation shortly. Make sure to submit your cash/check payment to reservation.earliest_session.cash_reservations_information"
  end

  def complete_with_stripe
    # Create new credit card from stripToken param, or retrieve it from Stripe account.
    handle_token
    
    unless @credit_card.nil?
     
      @charge_amount = session[:reservation_price]['fractional'].to_i
      @stripe_charger = StripeCharger.new(current_user, @credit_card, @charge_amount, "test payment")
      @asdasd.sdas
      @stripe_charger.charge!
     
      if @stripe_charger.success?

        amount_str = number_to_currency(@stripe_charger.order_total_in_dollars)

        customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)
        card_suffix = customer['sources']['data'][0]['last4']
  
        cc_info = Hash.new
        cc_info[:customer_id] = current_user.stripe_customer_id
        cc_info[:card_suffix] = card_suffix
        if @user.stored_stripes[0].nil?
          User.transaction do

            sps = StoredStripe.new( :user => @user,
                                    :customer_id => cc_info[:customer_id],
                                    :card_suffix => cc_info[:card_suffix]
                                  )
            sps.save!
          end
        end
        @user.stored_stripes.reload

        r = reserve_tickets(Reservation::PD_CREDIT, @user, @conductor_wish, @contact_phone,
        session[:reservation_details], @stripe_charger.charge!['id'],
        session[:reservation_price], session[:wait_list_id])

        redirect_to :action => "my_reservations",
                    notice: "Thank you for making a reservation with #{Setting::NAME}!\nYou will receive an e-mail confirmation shortly. Make sure to submit your cash/check payment to reservation.earliest_session.cash_reservations_information"
        return
      else
        flash[:error] = @stripe_charger.declined_explanation
      end
    else
      # flash[:error] = "Invalid credit card."
    end
    # In the case fail, go to origin page.
    redirect_to :action => "create"
  end

  def my_reservations
    @reservations = @user.reservations
  end

  def my_wait_list_reservations
    @wlrs = @user.wait_list_reservations.where("(spot_opened_at IS NULL) OR (spot_opened_at > ?)", Setting.earliest_valid_wait_list_opening)
  end

  def get_on_wait_list
    session[:wait_list_id] = params[:id]
    if current_user.nil?
      flash[:error] = "Please log in or verify your student credentials before continuing with your wait list reservation"
      # store_location
      redirect_to :controller => "user", :action => "login"
      return
    else
      # binding.pry
      # if user is not already on the wait list for this bus
      if WaitListReservation.where("user_id = ? and bus_id = ?", @user.id, params[:id]).first.nil?
        b = Bus.find(params[:id])
        if b.has_a_wait_list?
          wlr = WaitListReservation.create(:user => @user, :bus => b)
          Notifications.wait_list_success(@user, wlr).deliver_later
          flash[:success] = "You successfully reserved a spot on the wait list. You will be notified by email if a spot opens up."
        else
          flash[:error] = "There is no wait list for the specified bus. Please go ahead and buy a ticket."
        end
      else
        flash[:error] = "You were already on the wait list for the specified bus. No need to get another spot."
      end
      session[:wait_list_id] = nil
      redirect_to :controller => "index", :action => "index"
    end
  end

  def cancel_wait_list_reservation
    wlr = WaitListReservation.find(params[:id])
    if wlr.nil? || (wlr.user_id != @user.id)
      redirect_to :action => "my_wait_list_reservations"
    else
      wlr.destroy
      flash[:success] = "Canceled the selected wait list spot. Thank you."
      redirect_to :action => "my_wait_list_reservations"
    end
  end

  def modify
    @reservation = @user.reservations.find(params[:id])
    case request.method
    when 'GET'
      render
      return
    when 'POST'
      refund_amt = "0".to_money.fractional

      @charge = @user.stored_stripes
      params[:rt].each do |rt|
        reservation_ticket = ReservationTicket.where(id: rt).first
        next if reservation_ticket.nil?
        numbers_of_tickets = params[:rt][rt]

        if "0" == numbers_of_tickets
          refund_amt += reservation_ticket.bus.route.to_m.fractional * reservation_ticket.quantity
          
          reservation_ticket.destroy
        else
          difference = reservation_ticket.quantity.to_i - numbers_of_tickets.to_i
          refund_amt += reservation_ticket.bus.route.to_m.fractional * difference
          reservation_ticket.quantity = numbers_of_tickets
          reservation_ticket.save!
        end
      end
      refund_amt = (refund_amt).to_i
      refund = Stripe::Refund.create({
          charge: @reservation.charge_id,
          amount: refund_amt,
      })
      @reservation.reload

      if @reservation.payment_status == Reservation::UNPAID
        flash[:success] = "Modified your reservation successfully"
      elsif @reservation.payment_status == Reservation::PD_CASH
        unless refund_amt.zero?
          Notifications.reservation_modified_by_user(
            @user, @reservation.id, refund_amt.to_s
          ).deliver_later
        end
        flash[:success] = "Modified your reservation successfully,\n we will refund you #{refund_amt/100}"
      elsif @reservation.payment_status == Reservation::PD_CREDIT
        error_message = @reservation.cc_refund(refund_amt)
        if error_message.nil?
          flash[:success] = "Modified your reservation successfully,\n your credit card was refunded #{refund_amt/100}"
        else
          flash[:error] = "Modified your reservation successfully,\n but we had trouble refunding your credit card.\n\n Please contact a system administrator\nand reference transaction id ##{@reservation.charge_payment_event.transaction_id}."
        end
      end

      killed_whole_reservation = false
      if @reservation.reservation_tickets.size == 0
        @reservation.destroy
        killed_whole_reservation = true
      else
        @reservation.total = (@reservation.total.to_money.fractional - refund_amt).to_s
        @reservation.save!
      end
      Notifications.reservation_modify_success(@user, @reservation).deliver_later
      redirect_to :action => "my_reservations"
    end
  end

  def process_cc(user, cond_wishes, cond_phone, cc_info, reservation_details, reservation_price, wait_list_id)
    tr = nil
    r = nil
    begin
      User.transaction do
        # save the entered name / address information?
        if !cc_info[:store_cc_info].nil?
          sps = StoredPaymentAddress.new(:user => user,
                                         :name_on_card => cc_info[:name_on_card],
                                         :address_one => cc_info[:address_one],
                                         :city => cc_info[:city],
                                         :state => cc_info[:state],
                                         :zip => cc_info[:zip])
          sps.save!
        end

        # reserve the tickets
        r = reserve_tickets(Reservation::PD_CREDIT, user, cond_wishes, cond_phone, reservation_details, reservation_price, wait_list_id)

        # Make payment with credit card
        config = YAML.load_file(File.dirname(__FILE__) + "/../../config/credentials.yml")

        transaction = Transaction.new(
                        config["api_login_id"],
                        config["api_transaction_key"],
                        :gateway => config["api_environment_mode"])

        request = CreateTransactionRequest.new

        request.transactionRequest = TransactionRequestType.new()
        amount = reservation_price['fractional'].to_i / reservation_price['currency']['subunit_to_unit'].to_i
        request.transactionRequest.amount = amount.to_s
        request.transactionRequest.payment = PaymentType.new
        request.transactionRequest.payment.creditCard = CreditCardType.new(cc_info[:card_number],
            "#{cc_info[:expiration_month]}/#{cc_info[:expiration_year]}", cc_info[:ccv])
        request.transactionRequest.transactionType = TransactionTypeEnum::AuthCaptureTransaction

        response = transaction.create_transaction(request)

        if response != nil
          if response.messages.resultCode == MessageTypeEnum::Ok
            if response.transactionResponse != nil && response.transactionResponse.messages != nil
              puts "Successful charge (auth + capture) (authorization code: #{response.transactionResponse.authCode})"
              puts "Transaction ID: #{response.transactionResponse.transId}"
              puts "Transaction Response Code: #{response.transactionResponse.responseCode}"
              puts "Code: #{response.transactionResponse.messages.messages[0].code}"
              puts "Description: #{response.transactionResponse.messages.messages[0].description}"
            else
              puts "Transaction Failed"
              if response.transactionResponse.errors != nil
                puts "Error Code: #{response.transactionResponse.errors.errors[0].errorCode}"
                puts "Error Message: #{response.transactionResponse.errors.errors[0].errorText}"
                error_msg = "Error Code: #{response.transactionResponse.errors.errors[0].errorCode} \n" +
                            "Error Message: #{response.transactionResponse.errors.errors[0].errorText}"
              end
              raise TransportappError, error_msg
              # return false
            end
          else
            puts "Transaction Failed"
            if response.transactionResponse != nil && response.transactionResponse.errors != nil
              puts "Error Code: #{response.transactionResponse.errors.errors[0].errorCode}"
              puts "Error Message: #{response.transactionResponse.errors.errors[0].errorText}"
              error_msg = "Error Code: #{response.transactionResponse.errors.errors[0].errorCode} \n" +
                          "Error Message: #{response.transactionResponse.errors.errors[0].errorText}"
            else
              puts "Error Code: #{response.messages.messages[0].code}"
              puts "Error Message: #{response.messages.messages[0].text}"
              error_msg = "Error Code: #{response.messages.messages[0].code} \n" +
                          "Error Message: #{response.messages.messages[0].text}"
            end
            raise TransportappError, error_msg
            # return false
          end
        else
          puts "Response is null"
          error_msg = "Failed to charge card. Response is null."
          raise TransportappError, error_msg
          # return false
        end


        begin
          Notifications.cc_reservation_create_success(user, r).deliver_later
        rescue
          return "Transaction complete and reservation saved, but we could not send an email confirmation.\nPlease see your 'My Reservations' and contact a System Administrator if you need more information.", r
        end
      end
    rescue TransportappError => error_message
      return error_message, nil
    rescue TransportappGatewayError => error_message
      return "Error received while processing your credit card: \n" + error_message.to_s, nil
    end
    return nil, r
  end

  def process_cash(user, cond_wishes, cond_phone, reservation_details, reservation_price, wait_list_id)
    r = nil # the reservation
    begin
      User.transaction do
        r = reserve_tickets(Reservation::UNPAID, user, cond_wishes, cond_phone, reservation_details, reservation_price, wait_list_id)
        Notifications.cash_reservation_create_success(user, r).deliver_later
      end
    rescue TransportappError => error_message
      return error_message, nil
    end
    return nil, r
  end

  def reserve_tickets(pay_type, user, cond_wishes, cond_phone, reservation_details, charger_id, reservation_price, wait_list_id)
    r = Reservation.new(:user => user,
                        :charge_id => charger_id,
                        :payment_status => pay_type)
    r.save!

    if cond_wishes
      user.phone = cond_phone
      user.save!
    end

    # are we taking someone off the wait list? if so, take care of their wait list entry
    if !wait_list_id.nil?
      wlr = WaitListReservation.find(wait_list_id)
      if wlr.user != user
        raise TransportappError, "Problem - you were trying to reserve a wait list spot for someone else's account?"
      end
      wlr.destroy
    end

    reservation_total = Money.new(0)
    reservation_details.each do |rd|
      bus = Bus.where(id: rd[0]['id']).first
      reservation_total = reservation_total + (bus.to_m * rd[1].to_i)
      num_seats_requested = rd[1].to_i
      if(num_seats_requested <= bus.seats_remaining)
        bus.occupied_seats += num_seats_requested
        bus.save!
        rt = ReservationTicket.new(:reservation => r,
                                   :bus => bus,
                                   :quantity => num_seats_requested,
                                   :conductor_wish => (cond_wishes ? 1 : 0))
        rt.save!
      else
        # gotta do the raise for the transaction rollback
        raise TransportappError, "One or more of the buses you requested tickets for\nno longer has seats remaining."
      end
    end

    # need to save the total
    r.total = reservation_total.to_s
    r.save!

    # if !reservation_total.eql?(reservation_price)
    #   raise "Reservation total as calculated did not match what we had in the server session -- possible hack attempt."
    # end
    return r
  end

  private

  # def credit_card_params
  #   params.require(:credit_card).permit(:token)
  # end

  def handle_token
    @stripe_token = params[:stripeToken]
    unless @stripe_token.blank?
      customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)
      # card_suffix = customer['sources']['data'][0]['last4']
      @credit_card = current_user.credit_cards.new(
          # :last_4 => card_suffix,
          #   :kind => customer['sources']['data'][0]['brand'],
          #   :exp_mo => customer['sources']['data'][0]['exp_month'],
          #   :exp_year => customer['sources']['data'][0]['exp_year'],
          #   :stripe_card_id => customer['sources']['data'][0]['id'],
            :token => params[:stripeToken])
      if @credit_card.save
        # do nothing
      else
        # do nothing
      end
    end
  end

  def number_to_currency(number)
    @amount = number / 100
    return @amount
  end

end
