class ChangeTripReportTokenLength < ActiveRecord::Migration[5.1]
  def self.up
    change_column "buses", "report_token", :string, :limit => 40
  end

  def self.down
  end
end

