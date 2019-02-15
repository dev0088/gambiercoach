# require 'ajax_scaffold'

class Setting < ActiveRecord::Base

  SCHOOL = ENV['SCHOOL']
  EXAMPLE_USERNAME = ENV['smithj']
  NAME = ENV["APP_NAME"]
  EMAIL = ENV['EMAIL_SUFFIX']
  ADMIN_EMAIL = ENV['ADMIN_EMAIL']
  FROM_EMAIL = ENV['FROM_EMAIL']
  SERVER_URL = ENV['SERVER_URL']

  validates_numericality_of :max_tickets_purchase, :only_integer => true
  after_save :update_relevant_fields
  validates_format_of :wait_list_opening_window, :with => /[0-9]{1,2}(\.5)?/

  def self.reservations_closing_time
    s = first
    unless s.nil?
      return s.reservations_closing_time
    else
      return nil
    end
  end
  def self.max_tickets_purchase
    s = first
    unless s.nil?
      return s.max_tickets_purchase
    else
      return 2
    end
  end
  def self.daily_payment_reminder_time
    s = first
    unless s.nil?
      return s.daily_payment_reminder_time
    else
      return nil
    end
  end
  def self.wait_list_opening_window
    s = first
    unless s.nil?
      return s.wait_list_opening_window
    else
      return nil
    end
  end

  def self.earliest_valid_wait_list_opening
    s = first
    unless s.nil?
      return Time.now - s.wait_list_opening_window.to_f.hours
    else
      return nil
    end
  end

  private

  def update_relevant_fields
    Bus.all.each do |bus|
      bus.set_reservations_closing_date
      bus.save
    end
  end
end
