class CreditCard < ApplicationRecord
  belongs_to :owner, polymorphic: true

  validates_uniqueness_of :stripe_card_id, scope: [:owner]

  attribute :token

  before_create :create_stripe_card!
  before_destroy :destroy_stripe_card!

  def self.create_from_stripe(stripe_id)
    resource = Stripe::Card.retrieve(stripe_id)
    record = CreditCard.find_by_stripe_card_id(resource.id)
    record.save!
  end

  def self.update_from_stripe(stripe_id)
    create_from_stripe(stripe_id)
  end

  private

  def as_stripe_card
    customer = owner.as_stripe_customer
    @as_stripe_card ||= customer.deleted? ? nil : owner.as_stripe_customer.sources.retrieve(stripe_card_id)
  rescue Stripe::InvalidRequestError => e
    nil
  end

  def create_stripe_card!
    begin
      # source = owner.as_stripe_customer.sources.create(email: email, source: token)
      stripe_customer = owner.as_stripe_customer
      unless stripe_customer.present?
        # Create new stripe customer
        owner.create_stripe_customer!

        stripe_customer = owner.as_stripe_customer
        source = stripe_customer.sources.create(source: token)
        owner.as_stripe_customer.default_source = source.id
        owner.as_stripe_customer.save
        assign_attributes(stripe_card_id: source.id, exp_mo: source.exp_month, exp_year: source.exp_year, last_4: source.last4, kind: source.brand)
      end


    rescue Stripe::CardError => e
      self.errors.add(:base, e.message)
    end
  end

  def destroy_stripe_card!
    as_stripe_card&.delete
  end
end