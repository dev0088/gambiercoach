class ManagerController < ApplicationController
  layout "admin"
  before_action :admin_login_required, :except => :trip_report
  ssl_required :create_reservation

  def bus
    @b = Bus.find(params[:id], :include => [:reservation_tickets, :wait_list_reservations])
  end
  
  def system_reset_options
    case request.method
    when :get
      render
      return
    when :post
      if !params[:clear_all_reservations].nil?
        Reservation.transaction do
          Reservation.destroy_all()
          WaitListReservation.destroy_all()
          CreditPaymentEvent.destroy_all()
          Bus.update_all("occupied_seats = 0")
          TripReport.destroy_all()
          WalkOn.destroy_all()
        end
      elsif !params[:clear_all_users].nil?
        User.transaction do
          User.destroy_all()
        end
      end
      flash[:success] = "Operation complete."
      redirect_to :controller => "admin", :action => "index"
    end
  end
  
  def email_bus
    @bus = Bus.find(params[:id])
    if params[:email_address].empty?
      flash[:error] = "Please enter an email recipient"
      redirect_to :controller => "admin", :action => "index"
    end

    email_txt = "Bus: " + @bus.departure.strftime("%A, %B %d") + " departing " + @bus.starting_point + " for " + @bus.ending_point + " at " + @bus.departure.strftime("%I:%M %p") + "\n\n"
    email_txt << " res # -- student login id\n"
    email_txt << "---------------------------\n"
    @bus.reservation_tickets.find(:all, :order => "reservations.id ASC", :include => :reservation).each do |rt|
      for i in 0...rt.quantity
        email_txt << sprintf("%6u", rt.reservation.id)+" -- "+rt.reservation.user.login_id+"\n"
      end
    end
    @subject = "bus list / " + @bus.departure.strftime("%A, %B %d") + " departing " + @bus.starting_point + " for " + @bus.ending_point + " at " + @bus.departure.strftime("%I:%M %p")
    Notifications.deliver_admin_report(@subject,
                                       email_txt,
                                       params[:email_address])
    flash[:success] = "email sent"
    redirect_to :action => "bus", :id => @bus.id    
  end
  
  def session_conductors
    @s = TransportSession.find(params[:id], :include => :buses)
    case request.method
    when :get
      render
      return
    when :post
      params[:rt].each do |rt|
        reservation_ticket = ReservationTicket.find(rt[0])
        if rt[1] == "1" && reservation_ticket.conductor_status == 0
          Notifications.deliver_student_conductor_designation(reservation_ticket.reservation.user, reservation_ticket.bus)
        end
        reservation_ticket.conductor_status = rt[1]
        reservation_ticket.save!
      end
      flash[:success] = "Saved your conductor designations"
      render
      return
    end
  end
  
  def session_reservations
    @reservations = []
    @s = TransportSession.find(params[:id])
    @buses = @s.buses
    @buses.each do |b|
      @reservations += b.reservations
    end
    @reservations = @reservations.uniq
    
    case request.method
    when :get
      render
      return
    when :post
      
    end
  end
  
  def edit_reservation
    @reservation = Reservation.find(params[:id])
    case request.method
    when :get
      render
      return
    when :post
      refund_amt = "0".to_money
      params[:rt].each do |rt|
        reservation_ticket = ReservationTicket.find(rt[0])
        if "0" == rt[1]
          refund_amt = reservation_ticket.bus.route.to_m * reservation_ticket.quantity
          reservation_ticket.destroy
        else
          difference = reservation_ticket.quantity.to_i - rt[1].to_i
          refund_amt = reservation_ticket.bus.route.to_m * difference
          reservation_ticket.quantity = rt[1]
          if params[reservation_ticket.id.to_s + "_conductor"] == "yes"
	    if reservation_ticket.conductor_status == 0
	      Notifications.deliver_student_conductor_designation(reservation_ticket.reservation.user, reservation_ticket.bus)
	    end
            reservation_ticket.conductor_status = 1
          else
            reservation_ticket.conductor_status = 0
          end
          reservation_ticket.save!
        end
      end
      
      @reservation.reload

      if refund_amt.zero?
        flash[:success] = "Modified the reservation successfully<br />No ticket number changes made."
      elsif (@reservation.payment_status == Reservation::UNPAID) || (@reservation.payment_status == Reservation::PD_STUDENT_ID)
        flash[:success] = "Modified the reservation successfully"        
      elsif @reservation.payment_status == Reservation::PD_CASH
        flash[:success] = "Modified the reservation successfully<br /> refund owed is #{refund_amt}"        
      elsif @reservation.payment_status == Reservation::PD_CREDIT
        error_message = @reservation.cc_refund(refund_amt)
        error_message = nil
        if error_message.nil?
          flash[:success] = "Modified the reservation successfully<br /> the credit card was refunded #{refund_amt}"
        else
          flash[:error] = "Modified the reservation successfully<br /> but we had trouble refunding the credit card.<br /><br /> Manually credit the transaction id ##{@reservation.charge_payment_event.transaction_id} for #{refund_amt}."
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
      redirect_to :controller => "admin", :action => "index"
    end
  end

  def create_reservation
    case request.method
    when :get
      render
      return
    when :post
      user = nil
      if params[:user_id] == "--"
        if params[:new_user_login] == ""
          flash.now[:error] = "Select a user"
          render
          return
        else
          user = User.new(:verified => 1,
                           :new_password => "default")
          user.login_id = params[:new_user_login]
          unless user.save
            flash[:error] = "Problems creating the user: <br />"
            flash[:error] += user.errors.full_html_error_string
            render
            return
          end
        end
      else
        user = User.find(params[:user_id])
      end
      
      # wants to be a conductor?
      conductor_wish = params[:conductor].nil? ? false : true

      # parse the schedule
      reservation_requests, reservation_price, cash_reservations_allowed = parse_schedule_selections(params)

      if reservation_requests.size == 0
        flash.now[:error] = "No tickets selected for transaction"
        render
        return
      end

      # assume no errors till we report them down the line
      error_message = nil
      
      # CASH?
      if !params[:cash_submit].nil?
        r = nil # the reservation
        # begin
          User.transaction do
            # check to see if they were checked "paid"
            pay_status = Reservation::UNPAID
            if !params[:mark_as_paid].nil?
              pay_status = Reservation::PD_CASH
            end
            
            r = save_reservation(pay_status, user, conductor_wish, reservation_requests, reservation_price)
            Notifications.deliver_cash_reservation_create_success(user, r)
          end
        # rescue TransportappError => error_msg
        #   error_message = error_msg
        # end
      # STUDENT ID?
      elsif !params[:student_id_submit].nil?
        if params[:student_id].nil? || (params[:student_id].length < 7 || params[:student_id].length > 8)
          flash.now[:error] = "Student ID should be 7 characters long.<br/>Please exclude the leading 'W.'"
          render
          return
        end
        User.transaction do
          r = save_reservation(Reservation::PD_STUDENT_ID, user, conductor_wish, reservation_requests, reservation_price, params[:student_id])
          Notifications.deliver_cash_reservation_create_success(user, r)
        end
      # OR, CREDIT...
      else
        tr = nil
        r = nil
        begin
          User.transaction do
            # reserve the tickets
            r = save_reservation(Reservation::PD_CREDIT, user, conductor_wish, reservation_requests, reservation_price)

            cc_info = params[:cc_info]
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

#                                           :test_transaction => "true")
                                           # note that "normal authorization" => "AUTH_CAPTURE"
            begin
              tr.submit
            rescue
              error_message = tr.error_message
            end
            if tr.result_code != 1
              raise TransportappGatewayError, tr.error_message
            end
          end
          begin
            cpe = CreditPaymentEvent.create!(:user => user,
                                             :reservation => r,
                                             :transaction_amt => reservation_price.to_s,
                                             :response_code => tr.result_code,
                                             :transaction_type => "admin auth/capture",
                                             :transaction_id => tr.transaction_id,
                                             :error_code => nil,
                                             :error_message => nil,
                                             :authorization => tr.authorization,
                                             :avs_code => tr.avs_code,
                                             :cvv2_response => tr.cvv2_response,
                                             :cavv_response => tr.cavv_response,
                                             :cc_last_four => params[:cc_info][:card_number][-4,4])
          rescue
            logger.fatal "\n\nMAJOR PROBLEM -- TRANSACTION SENT BUT CREDIT PAYMENT EVENT NOT RECORDED -- USER = #{user.id}"
            logger.fatal "USER NOTIFIED, GIVEN GATEWAY TRANSACTION ID AND ASKED TO CONTACT SYSTEM ADMINISTRATOR\n\n"
            error_message = "Transaction only partially complete. Please contact a system administrator for assistance.<br />Reference the following transaction identifier: #{tr.transaction_id}"
          end
          begin
            Notifications.deliver_cc_reservation_create_success(user, r)
          rescue
            error_message = "Transaction complete and reservation saved, but we could not send an email confirmation."
          end
        rescue TransportappError => error_msg
          error_message = error_msg
        rescue TransportappGatewayError => error_message
          error_message = "error while processing the credit card<br />" + error_message
        end
      end
      
      if error_message.nil?
        flash.now[:success] = "Created the reservation for #{user.login_id}"
      else
        flash.now[:error] = "Problem while creating the reservation<br />" + error_message
      end
      render
      return
    end
  end

  # when get without id, display a blank user
  # when get with id, load up a user for editing
  # when post, save the user in question
  def create_edit_user
    case request.method
    when :get
      if !params[:id].nil?
        @user = User.find(params[:id])
      else
        @user = nil
      end
      render
      return
    when :post
      if params[:id].nil?
        @user = User.new(:verified => 1,
                         :new_password => "default")
      else
        @user = User.find(params[:id])
      end
      @user.login_id = params[:login_id]
      @user.phone = params[:phone]
      if @user.save
        flash[:success] = "Saved the user: " + @user.login_id
        redirect_to :action => "users"
      else
        flash[:error] = "Problems with saving the user: <br />"
        flash[:error] += @user.errors.full_html_error_string
        render
        return
      end
    end
  end
  
  def find_user
    case request.method
    when :get
      @user = User.find(:first, :conditions => ["login_id = ?", params[:login_id]])
      if @user.nil?
        flash[:error] = "Could not find a user with the login_id: " + params[:login_id]
        redirect_to :controller => "admin", :action => "index"
        return
      else
        redirect_to :action => "create_edit_user", :id => @user.id
      end
    end
  end
  
  def send_user_forgot_password
    user = User.find(params[:id])
    key = user.generate_reset_password_token
    url = url_for(:controller => 'user', :action => 'change_forgot_password', :user_id => user.id, :auth_token => key)
    Notifications.deliver_forgot_password(user, url)
    flash[:success] = "emailed instructions for setting a new password to #{user.email}."
    redirect_to :action => "users"
  end
  
  def unpaid_walkons
    case request.method
    when :get
      @unpaid_wos = WalkOn.find(:all, :conditions => ["payment_status = ?", WalkOn::UNPAID])
      render
      return
    when :post
      marked_pd = 0
      params[:wo].each do |wo|
        if wo[1] == "mark_as_paid"
          w = WalkOn.find(wo[0])
          w.payment_status = WalkOn::PAID
          w.save!
          marked_pd += 1
        end
      end
      flash[:success] = "saved walk-ons<br />marked #{marked_pd} as paid"
      redirect_to :controller => "admin", :action => "index"
      return
    end    
  end
  
  def walkons_csv
    walkons = WalkOn.find(:all, :include => :bus)
    stream_csv do |csv|
      csv << ["reservation_id","price","login_id","conductor_wish","conductor_status","bus_route","bus_date","bus_time","bus_id","payment_status","name","mailbox","phone1","phone2","student_id"]
      walkons.each do |w|
        csv << ["",w.bus.route.price.to_s,w.login_id,"","",w.bus.readable_route,w.bus.departure.strftime("%Y_%m_%d"),w.bus.departure.strftime("%I:%M %p"),w.bus.id.to_s,w.payment_status,w.name,w.mailbox,w.phone1,w.phone2,w.student_id]
      end
    end
  end
  
  def all_reservations_csv
    reservations = Reservation.find(:all, :include => :user)
    stream_csv do |csv|
      csv << ["id","login_id","payment_status","current_total","created_at","last_modified_at","student_id"]
      reservations.each do |r|
        csv << [r.id.to_s,r.user.login_id,r.payment_status.to_s,r.total.to_s,time_string(r.created_at),time_string(r.last_modified_at),r.student_id]
      end
    end
  end

  def session_tickets_csv
    s = TransportSession.find(params[:id])
    tickets = ReservationTicket.find_by_sql(["select rt.* from reservation_tickets rt, transport_sessions ts, buses b, routes r where ts.id = ? and ts.id = r.transport_session_id and r.id = b.route_id and rt.bus_id = b.id",params[:id]])
    stream_csv do |csv|
      csv << ["reservation_id","price","login_id","conductor_wish","conductor_status","bus_route","bus_date","bus_time","bus_id","payment_status","student_id"]
      tickets.each do |t|
        for i in 1..(t.quantity)
          csv << [t.reservation_id.to_s,t.bus.route.price.to_s,t.reservation.user.login_id,t.conductor_wish.to_s,t.conductor_status.to_s,t.bus.readable_route,t.bus.departure.strftime("%Y_%m_%d"),t.bus.departure.strftime("%I:%M %p"),t.bus.id.to_s,t.reservation.payment_status.to_s,t.reservation.student_id]
        end
      end
    end
  end

  def unpaid_reservations
    case request.method
    when :get
      @unpaid_rs = Reservation.all_unpaid
      render
      return
    when :post
      marked_pd = 0
      canceled = 0
      params[:r].each do |r|
        if r[1] == "mark_as_paid"
          res = Reservation.find(r[0])
          res.payment_status = Reservation::PD_CASH
          res.save!
          Notifications.deliver_payment_received(res.user, res)
          marked_pd += 1
        elsif r[1] == "cancel"
          Reservation.destroy(r[0])
          canceled += 1
        end
      end
      flash[:success] = "saved unpaid reservations<br />#{canceled} canceled and #{marked_pd} marked as paid"
      redirect_to :controller => "admin", :action => "index"
      return
    end
  end

  def trip_report
    @bus = Bus.find_by_report_token(params[:id])
    case request.method
    when :get
      if @bus.nil?
        flash[:error] = "The URL you requested did not lead to a trip report form."
        redirect_to :controller => "index", :action => "index"
        return
      end
      render :layout => false
      return
    when :post
      if @bus.nil?
        flash[:error] = "The trip report you tried to file did not have a valid trip report token."
        redirect_to :controller => "index", :action => "index"
        return
      end
      
      # create and save trip report
      # create and save all walk-ons
      TripReport.transaction do
        tr = TripReport.new(:bus => @bus, :user => @bus.conductor, :refund_issued => 0, :on_time => params[:on_time], :comment => params[:comment])
        tr.save!
        for i in 1..30
          unless params["walk_on_#{i}"][:name] == "" && params["walk_on_#{i}"][:login_id] == ""
            wo = WalkOn.new
            wo.bus = @bus
            wo.name = params["walk_on_#{i}"][:name]
            wo.login_id = params["walk_on_#{i}"][:login_id]
            wo.mailbox = params["walk_on_#{i}"][:mailbox]
            wo.phone1 = params["walk_on_#{i}"][:phone1]
            wo.phone2 = params["walk_on_#{i}"][:phone2]
            wo.payment_status = 0
            wo.student_id = params["walk_on_#{i}"][:student_id]
            wo.save!
          end
        end
        
        usedTix = Hash.new
        params.keys.each do |p_key|
          if p_key =~ /.*_rt_.*$/
            if params[p_key] == "on"
              rtid = p_key.gsub(/(_.*)/,'')
              if usedTix.key?(rtid)
                usedTix[rtid] += 1
              else
                usedTix[rtid] = 1              
              end
            end
          end
        end

        usedTix.keys.each do |key|
          logger.warn key
          cur = ReservationTicket.find(key)
          TripReportUsedReservation.create!(:bus_id => @bus.id,
                                            :user_email => cur.reservation.user.email,
                                            :quantity_used => usedTix[key],
                                            :reservation_ticket_id => cur.id)
        end
      end
      flash[:success] = "Thank you for submitting your trip report.<br />We will contact you with a refund shortly."
      redirect_to :controller => "index", :action => "index"
      return
    end
  end

  def manage_trip_reports
    @s = TransportSession.find(params[:id])
    @trs = Array.new
    @only_unrefunded = params[:only_unrefunded]
    @s.buses.each do |b|
      if @only_unrefunded.nil?
        @trs << b.trip_report if !b.trip_report.nil?
      else
        @trs << b.trip_report if !b.trip_report.nil? && (b.trip_report.refund_issued == 0)
      end
    end
    case request.method
    when :get
      render
      return
    when :post
      @trs.each do |tr|
        if params["report_"+tr.id.to_s] == "refunded"
          tr.refund_issued = 1
          tr.save!
        else
          tr.refund_issued = 0
          tr.save!          
        end
      end
      render
      return
    end
  end

  def bus_trip_report_used_reservations
    @b = Bus.find(params[:id])
    @trurs = TripReportUsedReservation.find(:all, :conditions => ["bus_id = ?", params[:id]])
  end
  
  private
  
  def stream_csv
    filename_for_save = params[:action] + ".csv"
    headers["Content-Type"] ||= 'text/csv'
    headers["Content-Disposition"] ||= "attachment; filename=\"#{filename_for_save}\"" 
    render :text => Proc.new { |response, output|
      csv = FasterCSV.new(output, :row_sep => "\r\n") 
      yield csv
    }
  end

  def save_reservation(pay_status, user, cond_wishes, reservation_details, reservation_price, student_id=nil)
    r = Reservation.new(:user => user,
                        :payment_status => pay_status,
                        :student_id => student_id)
    r.save!
    
    reservation_total = Money.new(0)
    reservation_details.each do |rd|
      bus = rd[0].reload
      reservation_total = reservation_total + (rd[0].to_m * rd[1].to_i)
      num_seats_requested = rd[1].to_i
      bus.occupied_seats += num_seats_requested
      bus.save!
      rt = ReservationTicket.new(:reservation => r,
                                 :bus => bus,
                                 :quantity => num_seats_requested,
                                 :conductor_wish => (cond_wishes ? 1 : 0))
      rt.save!
    end

    # need to save the total
    r.total = reservation_total.to_s
    r.save!    
    return r
  end
end
