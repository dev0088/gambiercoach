require 'ajax_scaffold'

class TransportSession < ActiveRecord::Base
  has_many :routes, :dependent => :destroy
  has_many :buses, :through => :routes
  
  validates_length_of :name, :minimum => 1
  
  # active sessions are those whose opening date is after the current date and whose 
  # session closing date has not yet past...
  # NB: session closing date is set by the last bus to close its reservations
  def self.active_sessions
    find(:all, :conditions => ["reservations_opening_date <= ? AND session_closing_date > ?", Time.now, Time.now])
  end
  
  # future sessions are all sessions whose reservations opening date 
  # is in the future
  def self.future_sessions
    find(:all, :conditions => ["reservations_opening_date > ?", Time.now])
  end
  
  # pulls all the routes for a session ordered by the display_order
  # property for each route
  def routes_in_order
    routes.find(:all, :order => "display_order ASC")
  end  
end
