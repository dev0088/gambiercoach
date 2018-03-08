class ReservationsController < ApplicationController

  before_action:login_required, :except => [:create, :get_on_wait_list]
  before_action:load_user_if_logged_in, :only => [:create, :get_on_wait_list]
  ssl_required :complete
  ssl_allowed :create

  def student_conductor_terms
    render :layout => false
  end

  def create
    @reservation_requests = []
    @reservation_price = nil
    @wait_list_id = nil
    @cash_reservations_allowed = true
    
    # is someone coming from an open wait list spot's "purchase your ticket" jump?
    if !params[:wait_list_id].nil?
      wlr = WaitListReservation.find(:first,
                                     :conditions => ["id = ? AND spot_opened_at IS NOT NULL AND spot_opened_at > ?", params[:wait_list_id], Setting.earliest_valid_wait_list_opening])
      if wlr.nil?
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
    elsif !params[:new_request].nil?
      @reservation_requests, @reservation_price, @cash_reservations_allowed = parse_schedule_selections(params)
      session[:reservation_details] = @reservation_requests
      session[:reservation_price] = @reservation_price
      session[:cash_reservations_allowed] = @cash_reservations_allowed
      session[:wait_list_id] = nil
      
    # someone was reserving a spot off the wait list, then jumped to another page
    # like editing a stored address, and is now back...
    elsif !session[:wait_list_id].nil?
      @reservation_requests = session[:reservation_details]
      @reservation_price = session[:reservation_price]
      @cash_reservations_allowed = session[:cash_reservations_allowed]
      @wait_list_id = session[:wait_list_id]

    # if we're not coming from the schedule page, and we already 
    # have reservation request details for the session
    #
    # in other words, somebody created reservation request details but 
    # then needed to go log in or sign up
    elsif !session[:reservation_details].nil?
      @reservation_requests = session[:reservation_details]
      @reservation_price = session[:reservation_price]
      @cash_reservations_allowed = session[:cash_reservations_allowed]
      
    else
      
      # something went seriously wrong, we have no idea why the user is here! ;)
      raise
    end
  
    if @reservation_requests.empty?
      flash[:error] = "Please select one or more tickets to reserve before continuing"
      redirect_to :controller => "index", :action => "index"
      return
    end
    
    if !request.ssl?
      redirect_to "https://" + request.host + request.request_uri
      return
    end
  
    if @user.nil?
      flash[:error] = "Please log in or verify your student credentials before continuing with your reservation"
      store_location
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
    @conductor_wish = false
    @contact_phone = nil
    if params[:conductor] == "yes"
      @conductor_wish = true
      if params[:contact_phone].empty?
        @reservation_requests = session[:reservation_details]
        @reservation_price = session[:reservation_price]
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
        flash[:success] = "Thank you for making a reservation with #{Setting::NAME}!<br />You will receive an e-mail confirmation shortly. Make sure to submit your cash/check payment to #{reservation.earliest_session.cash_reservations_information}"
        redirect_to :action => "my_reservations"
        return
      else
        flash[:error] = error_msg
        redirect_to :action => "create"
      end
    elsif !params[:pay_by_student_id].nil? # paying by Student ID
      if params[:student_id].nil? || (params[:student_id].length < 7 || params[:student_id].length > 8)
        flash[:error] = "Your Student ID should be 7 characters long.<br/>Please exclude the leading 'W.'"
        redirect_to :action => "create"
        return
      end
      error_msg, reservation = process_student_id(@user, @conductor_wish, @contact_phone, session[:reservation_details], session[:reservation_price], session[:wait_list_id], params[:student_id])
      if error_msg.nil?
        flash[:success] = "Thank you for making a reservation with #{Setting::NAME}!<br />You will receive an e-mail confirmation shortly.<br />A charge will be placed on your term bill after your trip."
        redirect_to :action => "my_reservations"
        return
      else
        flash[:error] = error_msg
        redirect_to :action => "create"
      end
    elsif !params[:new_cc_submit].nil? # paying with a newly entered cc
      error_msg, reservation = process_cc(@user, @conductor_wish, @contact_phone, params[:new_cc], session[:reservation_details], session[:reservation_price], session[:wait_list_id])
      if error_msg.nil?
        flash[:success] = "Thank you for making a reservation with #{Setting::NAME}!<br />You will receive an e-mail confirmation shortly."
        redirect_to :action => "my_reservations"
        return
      else
        flash[:error] = error_msg
        redirect_to :action => "create"
      end
    else # paying with a stored set of payment information
      spa = StoredPaymentAddress.find(:first, :conditions => ["id = ? AND user_id = ?", params[:stored_payment_set], @user.id])
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
      
      error_msg, reservation = process_cc(@user, @conductor_wish, @contact_phone, cc_info, session[:reservation_details], session[:reservation_price], session[:wait_list_id])
      if error_msg.nil?
        flash[:success] = "Thank you for making a reservation with #{Setting::NAME}!<br />You will receive an e-mail confirmation shortly."
        redirect_to :action => "my_reservations"
        return
      else
        flash[:error] = error_msg
        redirect_to :action => "create"
        return
      end
    end
  end
  
  def my_reservations
    begin
	@reservations = @user.reservations
    rescue
      puts $!
    end
  end

  def my_wait_list_reservations
    @wlrs = @user.wait_list_reservations.find(:all, :conditions => ["(spot_opened_at IS NULL) OR (spot_opened_at > ?)", Setting.earliest_valid_wait_list_opening])
  end

  def get_on_wait_list
    if current_user.nil?
      flash[:error] = "Please log in or verify your student credentials before continuing with your wait list reservation"
      store_location
      redirect_to :controller => "user", :action => "login"
      return
    else
      # if user is not already on the wait list for this bus
      if WaitListReservation.find(:first, :conditions => ["user_id = ? and bus_id = ?", @user.id, params[:id]]).nil?
        b = Bus.find(params[:id])
        if b.has_a_wait_list?
          wlr = WaitListReservation.create(:user => @user, :bus => b)
          Notifications.deliver_wait_list_success(@user, wlr)
          flash[:success] = "You successfully reserved a spot on the wait list. You will be notified by email if a spot opens up."
        else
          flash[:error] = "There is no wait list for the specified bus. Please go ahead and buy a ticket."
        end
      else
        flash[:error] = "You were already on the wait list for the specified bus. No need to get another spot."
      end
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
    when :get
      render
      return
    when :post
      refund_amt = "0".to_money
      params[:rt].each do |rt|
        reservation_ticket = ReservationTicket.find(rt[0])
        if "0" == rt[1]
          refund_amt += reservation_ticket.bus.route.to_m * reservation_ticket.quantity
          reservation_ticket.destroy
        else
          difference = reservation_ticket.quantity.to_i - rt[1].to_i
          refund_amt += reservation_ticket.bus.route.to_m * difference
          reservation_ticket.quantity = rt[1]
          reservation_ticket.save!
        end
      end
      @reservation.reload

      if (@reservation.payment_status == Reservation::UNPAID) || (@reservation.payment_status == Reservation::PD_STUDENT_ID)
        flash[:success] = "Modified your reservation successfully"        
      elsif @reservation.payment_status == Reservation::PD_CASH
        unless refund_amt.zero?
          Notifications.deliver_reservation_modified_by_user(@user, @reservation.id, refund_amt.to_s)
        end
        flash[:success] = "Modified your reservation successfully,<br /> we will refund you #{refund_amt}"        
      elsif @reservation.payment_status == Reservation::PD_CREDIT
        error_message = @reservation.cc_refund(refund_amt)
        if error_message.nil?
          flash[:success] = "Modified your reservation successfully,<br /> your credit card was refunded #{refund_amt}"
        else
          flash[:error] = "Modified your reservation successfully,<br /> but we had trouble refunding your credit card.<br /><br /> Please contact a system administrator<br />and reference transaction id ##{@reservation.charge_payment_event.transaction_id}."
        end
      end

      killed_whole_reservation = false
      if @reservation.reservation_tickets.size == 0
        @reservation.destroy
        killed_whole_reservation = true
      else
        @reservation.total = (@reservation.total.to_money - refund_amt).to_s
        @reservation.save!
      end
      Notifications.deliver_reservation_modify_success(@user, @reservation)
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
        
        # process the credit card
        tr = Payment::AuthorizeNet.new(:amount => reservation_price.to_s,
                                       :card_number => cc_info[:card_number],
                                       :first_name => cc_info[:name_on_card].split(" ",2)[1],
                                       :last_name => cc_info[:name_on_card].split(" ",2)[0],
                                       :expiration => "#{cc_info[:expiration_month]}/#{cc_info[:expiration_year]}",
                                       :address => cc_info[:address_one],
                                       :city => cc_info[:city],
                                       :state => cc_info[:state],
                                       :zip => cc_info[:zip],
                                       :type => "normal authorization")
                                       # note that "normal authorization" => "AUTH_CAPTURE"
        begin
          tr.submit
        rescue
          raise TransportappGatewayError, tr.error_message
        end
        if tr.result_code != 1
          raise TransportappGatewayError, tr.error_message
        end
        begin
          cpe = CreditPaymentEvent.create!(:user => user,
                                           :reservation => r,
                                           :transaction_amt => reservation_price.to_s,
                                           :response_code => tr.result_code,
                                           :transaction_type => "auth/capture",
                                           :transaction_id => tr.transaction_id,
                                           :error_code => nil,
                                           :error_message => nil,
                                           :authorization => tr.authorization,
                                           :avs_code => tr.avs_code,
                                           :cvv2_response => tr.cvv2_response,
                                           :cavv_response => tr.cavv_response,
                                           :cc_last_four => cc_info[:card_number][-4,4])
        rescue
          logger.fatal "\n\nMAJOR PROBLEM -- TRANSACTION SENT BUT CREDIT PAYMENT EVENT NOT RECORDED -- USER = #{user.id}"
          logger.fatal "USER NOTIFIED, GIVEN GATEWAY TRANSACTION ID AND ASKED TO CONTACT SYSTEM ADMINISTRATOR\n\n"
          raise TransportappError, "Transaction only partially complete. Please contact a system administrator for assistance.<br />Reference the following transaction identifier: #{tr.transaction_id}"
        end
        begin
          Notifications.deliver_cc_reservation_create_success(user, r)
        rescue
          return "Transaction complete and reservation saved, but we could not send an email confirmation.<br />Please see your 'My Reservations' and contact a System Administrator if you need more information.", r
        end
      end
    rescue TransportappError => error_message
      return error_message, nil
    rescue TransportappGatewayError => error_message
      return "Error received while processing your credit card: <br />" + error_message, nil
    end
    return nil, r
  end
  
  def process_cash(user, cond_wishes, cond_phone, reservation_details, reservation_price, wait_list_id)
    r = nil # the reservation
    begin
      User.transaction do
        r = reserve_tickets(Reservation::UNPAID, user, cond_wishes, cond_phone, reservation_details, reservation_price, wait_list_id)
        Notifications.deliver_cash_reservation_create_success(user, r)
      end
    rescue TransportappError => error_message
      return error_message, nil
    end
    return nil, r
  end
  
  def process_student_id(user, cond_wishes, cond_phone, reservation_details, reservation_price, wait_list_id, student_id)
    r = nil # the reservation
    begin
      User.transaction do
        r = reserve_tickets(Reservation::PD_STUDENT_ID, user, cond_wishes, cond_phone, reservation_details, reservation_price, wait_list_id, student_id)
        Notifications.deliver_student_id_reservation_create_success(user, r)
      end
    rescue TransportappError => error_message
      return error_message, nil
    end
    return nil, r
  end
  
  def reserve_tickets(pay_type, user, cond_wishes, cond_phone, reservation_details, reservation_price, wait_list_id, student_id=nil)
    r = Reservation.new(:user => user,
                        :payment_status => pay_type,
                        :student_id => student_id)
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
      bus = rd[0].reload
      reservation_total = reservation_total + (rd[0].to_m * rd[1].to_i)
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
        raise TransportappError, "One or more of the buses you requested tickets for<br />no longer has seats remaining."
      end
    end

    # need to save the total
    r.total = reservation_total.to_s
    r.save!
    
    if !reservation_total.eql?(reservation_price)
      raise "Reservation total as calculated did not match what we had in the server session -- possible hack attempt."
    end    
    return r
  end
end
