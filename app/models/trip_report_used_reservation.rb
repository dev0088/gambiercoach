class TripReportUsedReservation < ActiveRecord::Base
  belongs_to :bus
  belongs_to :reservation_ticket
end
