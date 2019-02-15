class StripeController < BaseController
  def receive
    StripeEvent.execute(params)
    head :ok
  end
end
