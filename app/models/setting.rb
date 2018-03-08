require 'ajax_scaffold'

class Setting < ActiveRecord::Base

  SCHOOL = "Williams"
  EXAMPLE_USERNAME = "00abc"
  NAME = "Williams Transport"
  EMAIL = "@williams.edu"
  ADMIN_EMAIL = "motorcoach@wso.williams.edu"
  FROM_EMAIL = "motorcoach@wso.williams.edu"
  SERVER_URL = "http://www.williamstransport.org"

  validates_numericality_of :max_tickets_purchase, :only_integer => true
  after_save :update_relevant_fields
  validates_format_of :wait_list_opening_window, :with => /[0-9]{1,2}(\.5)?/
  
  def self.reservations_closing_time
    s = find(:first)
    unless s.nil?
      return s.reservations_closing_time
    else
      return nil
    end
  end
  def self.max_tickets_purchase
    s = find(:first)
    unless s.nil?
      return s.max_tickets_purchase
    else
      return 2
    end
  end
  def self.daily_payment_reminder_time
    s = find(:first)
    unless s.nil?
      return s.daily_payment_reminder_time
    else
      return nil
    end    
  end
  def self.wait_list_opening_window
    s = find(:first)
    unless s.nil?
      return s.wait_list_opening_window
    else
      return nil
    end        
  end
  
  def self.earliest_valid_wait_list_opening
    s = find(:first)
    unless s.nil?
      return Time.now - s.wait_list_opening_window.to_f.hours
    else
      return nil
    end    
  end
  
  private
  
  def update_relevant_fields
    Bus.find(:all).each do |bus|
      bus.set_reservations_closing_date
      bus.save
    end
  end
end
