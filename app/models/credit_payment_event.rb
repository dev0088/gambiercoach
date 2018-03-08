class CreditPaymentEvent < ActiveRecord::Base
  belongs_to :user
  belongs_to :reservation
  before_create 'self.created_at = Time.now'
  validates_associated :user
  validates_presence_of :response_code
  validates_presence_of :transaction_type
  
end