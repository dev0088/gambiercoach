# require 'ajax_scaffold'

class Bus < ActiveRecord::Base
  belongs_to :route
  has_one :trip_report
  has_many :trip_report_used_reservations
  has_many :reservation_tickets
  has_many :walk_ons
  has_many :wait_list_reservations
  has_many :reservations, :through => :reservation_tickets

  validates_presence_of :route
  validates_numericality_of :seats, :only_integer => true
  validates_associated :route
  validates_presence_of :reservations_closing_date, :message => "requires that the general setting for reservations closing time be set first"
  before_validation :set_reservations_closing_date
  after_save :update_session_closing_date
  after_save :update_waiting_list

  # @scaffold_columns = [
  #   AjaxScaffold::ScaffoldColumn.new(self, {:name => "route",
  #                                           :eval => "bus.route.readable_route",
  #                                           :sortable => false,
  #                                           :label => "Route"}),
  #   AjaxScaffold::ScaffoldColumn.new(self, {:name => "going_away",
  #                                           :label => "Going away?"}),
  #   AjaxScaffold::ScaffoldColumn.new(self, {:name => "departure",
  #                                           :label => "Departure Date/Time"}),
  #   AjaxScaffold::ScaffoldColumn.new(self, {:name => "seats",
  #                                           :label => "Seats"})
  # ]

  def conductor
    rt = self.reservation_tickets.where("conductor_status = 1").first
    if rt.nil?
      return nil
    else
      return rt.reservation.user
    end
  end

  def starting_point
    if self.going_away
      return self.route.point_a
    else
      return self.route.point_b
    end
  end

  def ending_point
    if self.going_away
      return self.route.point_b
    else
      return self.route.point_a
    end
  end

  def readable_route
    if self.going_away
      return self.route.point_a + " to " + self.route.point_b
    else
      return self.route.point_b + " to " + self.route.point_a
    end
  end

  def readable_name
    return self.readable_route + " -- " + time_string(self.departure)
  end

  def to_m
    return self.route.price.to_money
  end

  # a bus has a wait list if either there are people on the wait list
  # or the bus is full (all seats are occupied)
  def has_a_wait_list?
    return (wait_list_count > 0) || (seats <= occupied_seats)
  end

  def seats_remaining
    return seats - occupied_seats
  end

  def departed?
    return self.departure < Time.now
  end

  def cash_reservations_allowed?
    return self.route.transport_session.cash_reservations_closing_date > Time.now
  end

  def wait_list_count
    return WaitListReservation.where(bus_id: self.id).count
  end

  # represents the number of people who are currently on the wait list and do not have
  # a ticket held open for them
  def no_ticket_held_on_wait_list_count
    return WaitListReservation.where("bus_id = ? and spot_opened_at IS NULL", self.id).count
  end

  # reservations closing date for this bus is defined as the global setting
  # for the reservations closing "time" on the day prior to the bus's departure
  def set_reservations_closing_date
    the_time = Setting.reservations_closing_time
    if !the_time.nil?
      the_date = self.departure.ago(1.day)
      self.reservations_closing_date = Time.mktime(the_date.year, the_date.month, the_date.day,
                                                   the_time.hour, the_time.min, nil, nil)
    end
  end

  # the closing date for a session is defined as the latest bus reservations closing
  # date for buses in the session
  def update_session_closing_date
    current_closing_date = self.route.transport_session.session_closing_date
    if current_closing_date.nil? || self.reservations_closing_date > current_closing_date
      self.route.transport_session.session_closing_date = self.reservations_closing_date
      self.route.transport_session.save
    end
  end

  def update_waiting_list
    earliest_open_spot = Setting.earliest_valid_wait_list_opening
    # total seats on bus - seats reserved by tickets - wait list spots that currently have a ticket held open for reserving
    newly_available_seats = seats - occupied_seats - WaitListReservation.where("bus_id = ? AND spot_opened_at IS NOT NULL AND spot_opened_at > ?", self.id, earliest_open_spot).count
    if (newly_available_seats > 0) && (self.wait_list_count > 0)
      wlrs = self.wait_list_reservations.where("spot_opened_at IS NULL").order("created_at ASC")
      number_to_open = (wlrs.size > newly_available_seats) ? newly_available_seats : wlrs.size
      for i in 0...number_to_open
        wlrs[i].spot_opened_at = Time.now
        wlrs[i].save!
        Notifications.wait_list_spot_opened(wlrs[i].user, wlrs[i].bus).deliver_now
      end
    end
  end
end
