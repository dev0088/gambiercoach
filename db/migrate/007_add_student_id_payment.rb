class AddStudentIdPayment < ActiveRecord::Migration[5.1]
  def self.up
    add_column "reservations", :student_id, :string, :limit => 20
  end

  def self.down
  end
end
