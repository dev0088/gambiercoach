module ReservationsHelper
  def convert_reservation_price(reservation_price)
    # "#{reservation_price["currency"]["html_entity"]}#{reservation_price["fractional"].to_f / reservation_price["currency"]["subunit_to_unit"].to_f}"
    if reservation_price.nil?
      "$0.00"
    else
      reservation_price.format
    end
  end

  def is_stripe_payment
    ENV['PAYMENT_METHOD'] == 'stripe' ? true : false
  end
end
