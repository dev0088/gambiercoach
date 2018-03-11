class WaitListReservation < ActiveRecord::Base
  belongs_to :bus
  belongs_to :user
  before_create :update_created_at

  def update_created_at
    self.created_at = Time.now
  end

  def has_opening?
    return (!self.spot_opened_at.nil?) && (self.spot_open_till > Time.now)
  end

  def spot_open_till
    return self.spot_opened_at + Setting.wait_list_opening_window.to_f.hours unless self.spot_opened_at.nil?
    return nil
  end

  def spot_number
    return WaitListReservation.where("bus_id = ? AND spot_opened_at IS NULL AND created_at < ?", self.bus_id, self.created_at).count + 1
  end
end
