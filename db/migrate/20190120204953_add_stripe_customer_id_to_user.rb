class AddStripeCustomerIdToUser < ActiveRecord::Migration[5.1]
  def change
    add_index :users, :stripe_customer_id
  end
end
