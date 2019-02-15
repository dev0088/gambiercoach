class CreateStripeEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :stripe_events do |t|
      t.string :stripe_event_id
      t.string :kind
      t.text :error

      t.timestamps
    end
  end
end
