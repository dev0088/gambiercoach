class WalkOn < ActiveRecord::Base
  belongs_to :bus
  WalkOn::UNPAID = 0
  WalkOn::PAID = 1

  def self.to_csv
    CSV.generate(headers: true) do |csv|
      csv << ["reservation_id", "price", "login_id", "conductor_wish",
              "conductor_status", "bus_route", "bus_date", "bus_time",
              "bus_id", "payment_status", "name", "mailbox",
              "phone1", "phone2", "student_id"]
      all.each do |walkon|
        # csv << [reservation.id, reservation.user.login_id, reservation.payment_status, reservation.total, reservation.created_at, reservation.last_modified_at]
        csv << ["",
                walkon.bus.route.price.to_s,
                walkon.login_id,
                "",
                "",
                walkon.bus.readable_route,
                walkon.bus.departure.strftime("%Y_%m_%d"),
                walkon.bus.departure.strftime("%I:%M %p"),
                walkon.bus.id.to_s,
                walkon.payment_status,
                walkon.name,
                walkon.mailbox,
                walkon.phone1,
                walkon.phone2,
                walkon.student_id]
      end
    end
  end

end
