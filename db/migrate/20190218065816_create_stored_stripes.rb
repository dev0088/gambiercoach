class CreateStoredStripes < ActiveRecord::Migration[5.1]
  def change
    create_table :stored_stripes do |t|
      t.integer :user_id
      t.string :customer_id
      t.integer :card_suffix

      t.timestamps
    end
  end
end
