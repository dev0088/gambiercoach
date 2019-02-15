class StripeCharger

  APPROVED_CODE = 'approved_by_network'
  DECLINED_CODE = 'declined_by_network'

  def initialize(user, credit_card, amount, description)
    @user = user
    @credit_card = credit_card
    @amount = amount
    @description = description
    @charge = nil
    @card_error_message = nil
  end

  def order_total
    # @bundle.price_in_cents
    @amount
  end

  def order_total_in_dollars
    # Bundle.to_dollars(order_total)
    @amount
  end

  def order_description
    # @bundle.name
    @description
  end

  def success?
    return false if @card_error_message.present?
    @charge.outcome.network_status == APPROVED_CODE
  end

  def declined_explanation
    return nil if success?
    return @card_error_message if !@card_error_message.blank?
    reason = "An unknown error caused your transaction to be declined or unprocessed. Please contact us if you believe this to be in error."
    reason = case @charge.outcome.reason.to_sym
               when :expired_card
                 "Your card was declined because it is expired."
               when :not_sent_to_network
                 "Your transaction could not be sent to the payment network at this time."
               when :card_not_supported
                 "Your card does not support this type of purchase."
               when :currency_not_supported
                 "Your card does not support the specified currency (USD)."
             end
    reason
  end

  def info
    @charge
  end

  def charge!
    begin
      @charge = Stripe::Charge.create({
                                          amount: order_total,
                                          currency: 'usd',
                                          customer: @user.stripe_customer_id,
                                          description: order_description,
                                          source: @credit_card.stripe_card_id
                                      })
        #puts "\n#{@charge.inspect}\n"
    rescue Stripe::CardError => e
      @card_error_message = e.message
    rescue => e
      @card_error_message = "An unknown error occurred: #{e}"
    end
  end

end