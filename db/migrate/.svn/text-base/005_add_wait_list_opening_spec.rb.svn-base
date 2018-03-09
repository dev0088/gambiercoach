class AddWaitListOpeningSpec < ActiveRecord::Migration
  def self.up
    add_column "settings", :wait_list_opening_window, :string, :limit => 10
    add_column "wait_list_reservations", :spot_opened_at, :datetime
    remove_column "wait_list_reservations", :spot_open_till
  end

  def self.down
  end
end
