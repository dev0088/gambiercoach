class AddStudentIdToTripReport < ActiveRecord::Migration[5.1]
  def self.up
    change_column "buses", "report_token", :string, :limit => 40
    add_column "walk_ons", "student_id", :string, :limit => 20
  end

  def self.down
  end
end
