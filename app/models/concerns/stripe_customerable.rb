# frozen_string_literal: true

module StripeCustomerable
  extend ActiveSupport::Concern

  included do
    before_destroy do
      as_stripe_customer.delete
      # rescue Stripe::InvalidRequestError => e
      #   true
    end

    after_commit on: :create do
      create_stripe_customer_async!
    end
  end

  def as_stripe_customer
    @as_stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_id) if stripe_customer_id.present?
  end

  def self.create_from_stripe(stripe_id)
    resource = Stripe::Customer.retrieve(stripe_id)
    user = self.find_by_stripe_customer_id(resource.id)
    user.save!
  end

  def self.update_from_stripe(stripe_id)
    create_from_stripe(stripe_id)
  end

  def create_stripe_customer_async!
    create_stripe_customer!
  end

  def create_stripe_customer!
    return true if stripe_customer_id.present?
    customer = Stripe::Customer.create(stripe_customer_attributes)
    update_attribute(:stripe_customer_id, customer.id)
  end

  def create_stripe_customer_with_info(stripeToken)
    customer = Stripe::Customer.create(
        :email => email,
        :source  => stripeToken
    )
    update_attribute(:stripe_customer_id, customer.id)
  end

  def stripe_customer_attributes
    { email: email, metadata: { id: id, type: self.class.name } }
  end
end
