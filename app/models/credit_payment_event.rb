class CreditPaymentEvent < ActiveRecord::Base
  belongs_to :user
  belongs_to :reservation
  before_create :update_with_current_time
  validates_associated :user
  validates_presence_of :response_code
  validates_presence_of :transaction_type

  def update_with_current_time
    self.created_at = Time.now
  end
end
