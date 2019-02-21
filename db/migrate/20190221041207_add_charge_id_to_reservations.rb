class AddChargeIdToReservations < ActiveRecord::Migration[5.1]
  def change
    add_column :reservations, :charge_id, :string
  end
end
