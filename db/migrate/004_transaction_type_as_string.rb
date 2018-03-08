class TransactionTypeAsString < ActiveRecord::Migration[5.1]
  def self.up
    change_column "credit_payment_events", :transaction_type, :string, :limit => 20, :null => false
  end

  def self.down
  end
end
