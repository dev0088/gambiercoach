require 'csv'

class Reservation < ActiveRecord::Base
  belongs_to :user
  has_many :credit_payment_events
  has_many :reservation_tickets, :dependent => :destroy
  has_many :reservation_modifications, :dependent => :destroy
  before_create :update_created_at
  before_save :update_last_modified_at

  UNPAID = 0
  PD_CREDIT = 1
  PD_CASH = 2

  def update_created_at
    self.created_at = Time.now
  end

  def update_last_modified_at
    self.last_modified_at = Time.now
  end

  def charge_payment_event
    return self.credit_payment_events.where("transaction_type = 'admin auth/capture' or transaction_type = 'auth/capture'").first
  end

  def total_in_money
    return total.to_money
  end

  def past?
    self.reservation_tickets.each do |rt|
      if !rt.bus.departed?
        return false
      end
    end
    return true
  end

  def earliest_session
    earliest_bus = nil
    self.reservation_tickets.each do |rt|
      if earliest_bus.nil? || (rt.bus.departure < earliest_bus.departure)
        earliest_bus = rt.bus
      end
    end

    if earliest_bus.nil?
      raise "Earliest bus should never be nil -- if this happened, it implies that a reservation was in the system without any tickets?"
    end

    return earliest_bus.route.transport_session
  end

  def cc_refund(amt, caller=nil)
    error_message = nil
    transaction_type = nil
    begin
      cpe = self.charge_payment_event
      if cpe.nil?
        error_message = "Internal Error: no payment events for reservation id: #{self.id}"
        return
      end
      credit_not_complete = true

      # try a void first if the initial charge was less than 24 hours ago
      if cpe.created_at > (Time.now - 24.hours)
        tr = Payment::AuthorizeNet.new(:amount => amt.to_s,
                                       :transaction_id => cpe.transaction_id,
                                       :card_number => cpe.cc_last_four,
                                       :type => "VOID")
        begin
          tr.submit
          logger.fatal tr.response
        rescue
          logger.fatal tr.response
          logger.fatal tr.error_message
          # do nothing, because it might very well be because we need to do a credit rather than a void...
        end
        if tr.result_code == 1
          credit_not_complete = false
          begin
            if caller == "admin"
              transaction_type = "admin void"
            else
              transaction_type = "void"
            end
            cpe = CreditPaymentEvent.create!(:user => self.user,
                                             :reservation => self,
                                             :transaction_amt => amt.to_s,
                                             :response_code => tr.result_code,
                                             :transaction_type => transaction_type,
                                             :transaction_id => tr.transaction_id,
                                             :error_code => nil,
                                             :error_message => nil,
                                             :authorization => tr.authorization)
          rescue
            logger.fatal "\n\nMAJOR PROBLEM -- VOID TRANSACTION SENT BUT CREDIT PAYMENT EVENT NOT RECORDED -- USER = #{user.id}"
            logger.fatal "USER NOTIFIED, GIVEN GATEWAY TRANSACTION ID AND ASKED TO CONTACT SYSTEM ADMINISTRATOR\n\n"
            error_message = "Credit Transaction only partially complete.\nPlease contact a system administrator for assistance.\nReference the following transaction identifier: #{tr.transaction_id}"
          end
        end
      end

      # if we couldn't complete a void, try a credit
      if credit_not_complete
        tr = Payment::AuthorizeNet.new(:amount => amt.to_s,
                                       :transaction_id => cpe.transaction_id,
                                       :card_number => cpe.cc_last_four,
                                       :type => "CREDIT")
        begin
          tr.submit
          logger.fatal tr.response
        rescue
          logger.fatal tr.response
          logger.fatal tr.error_message
          raise TransportappGatewayError, tr.error_message
        end
        begin
          if caller == "admin"
            transaction_type = "admin credit"
          else
            transaction_type = "credit"
          end
          cpe = CreditPaymentEvent.create!(:user => self.user,
                                           :reservation => self,
                                           :transaction_amt => amt.to_s,
                                           :response_code => tr.result_code,
                                           :transaction_type => transaction_type,
                                           :transaction_id => tr.transaction_id,
                                           :error_code => nil,
                                           :error_message => nil,
                                           :authorization => tr.authorization)
        rescue
          logger.fatal "\n\nMAJOR PROBLEM -- CREDIT TRANSACTION SENT BUT CREDIT PAYMENT EVENT NOT RECORDED -- USER = #{user.id}"
          logger.fatal "USER NOTIFIED, GIVEN GATEWAY TRANSACTION ID AND ASKED TO CONTACT SYSTEM ADMINISTRATOR\n\n"
          error_message = "Credit Transaction only partially complete.\nPlease contact a system administrator for assistance.\nReference the following transaction identifier: #{tr.transaction_id}"
        end
      end

    rescue TransportappError => error_msg
      error_message = error_msg
    rescue TransportappGatewayError => error_message
      error_message = "error while processing the credit\n" + error_message.to_s
    end
  end

  def readable_payment_status
    case self.payment_status
    when UNPAID
      "unpaid"
    when PD_CREDIT
      "paid by a credit card"
    when PD_CASH
      "paid in cash"
    end
  end

  def self.all_unpaid
    return self.where("payment_status = ?", UNPAID)
  end

  def self.to_csv
    attributes = %w{id email name}

    CSV.generate(headers: true) do |csv|
      csv << column_names
      all.each do |reservation|
        csv << reservation.attributes.values
      end
    end
  end
end
