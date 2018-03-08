class ReservationTicket < ActiveRecord::Base
  belongs_to :reservation
  belongs_to :bus
  has_one :trip_report_used_reservation
  after_save :set_bus_seat_count
  after_destroy :set_bus_seat_count
  
  private

  def set_bus_seat_count
    count = 0
    rts = ReservationTicket.find(:all, :conditions => ["bus_id = ?", self.bus_id])
    rts.each do |rt|
      count += rt.quantity
    end
    b = Bus.find(self.bus_id)
    b.occupied_seats = count
    b.save!
    b.update_waiting_list
  end
end
