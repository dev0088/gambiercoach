class ReservationTicket < ActiveRecord::Base
  belongs_to :reservation
  belongs_to :bus
  has_one :trip_report_used_reservation
  after_save :set_bus_seat_count
  after_destroy :set_bus_seat_count

  # def self.to_csv
  #   CSV.generate(headers: true) do |csv|
  #     csv << ["reservation_id", "price", "login_id", "conductor_wish",
  #             "conductor_status", "bus_route", "bus_date", "bus_time",
  #             "bus_id"]
  #
  #     all.each do |reservation_ticket|
  #       for i in 1..(reservation_ticket.quantity)
  #         a
  #         csv << [reservation_ticket.reservation_id.to_s,
  #                 reservation_ticket.bus.route.price.to_s,
  #                 reservation_ticket.reservation.user.login_id,
  #                 reservation_ticket.conductor_wish.to_s,
  #                 reservation_ticket.conductor_status.to_s,
  #                 reservation_ticket.bus.readable_route,
  #                 reservation_ticket.bus.departure.strftime("%Y_%m_%d"),
  #                 reservation_ticket.bus.departure.strftime("%I:%M %p"),
  #                 reservation_ticket.bus.id.to_s]
  #       end
  #     end
  #   end
  # end

  private

  def set_bus_seat_count
    count = 0
    rts = ReservationTicket.where("bus_id = ?", self.bus_id)
    rts.each do |rt|
      count += rt.quantity
    end
    b = Bus.find(self.bus_id)
    b.occupied_seats = count
    b.save!
    b.update_waiting_list
  rescue ActiveRecord::RecordNotFound
    logger.error("Can't find bus with id #{self.bus_id} skipping quietly")
  end
end
