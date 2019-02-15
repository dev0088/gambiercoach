class AddOwnerTypeToCreditCard < ActiveRecord::Migration[5.1]
  def change
    add_column :credit_cards, :owner_type, :string
    add_index :credit_cards, [:owner_id, :owner_type]
    CreditCard.all.each do |credit_card|
      credit_card.update_attributes(:owner_id => credit_card.user_id, owner_type: 'User')
    end
  end
end
