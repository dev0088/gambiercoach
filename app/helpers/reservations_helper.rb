module ReservationsHelper
  def convert_reservation_price(reservation_price)
    "#{reservation_price["currency"]["html_entity"]}#{reservation_price["fractional"].to_f / reservation_price["currency"]["subunit_to_unit"].to_f}"
  end
end
