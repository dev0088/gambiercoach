class AddDailyPaymentReminderTime < ActiveRecord::Migration[5.1]
  def self.up
    add_column "settings", "daily_payment_reminder_time", :time
  end

  def self.down
  end
end
