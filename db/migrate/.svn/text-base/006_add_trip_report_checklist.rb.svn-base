class AddTripReportChecklist < ActiveRecord::Migration
  def self.up
    create_table :trip_report_used_reservations do |t|
      t.column :bus_id, :integer
      t.column :user_email, :string, :limit => 100
      t.column :quantity_used, :integer
      t.column :reservation_ticket_id, :integer
    end
  end

  def self.down
  end
end
