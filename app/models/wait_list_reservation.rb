class WaitListReservation < ActiveRecord::Base
  belongs_to :bus
  belongs_to :user
  before_create 'self.created_at = Time.now'
  
  def has_opening?
    return (!self.spot_opened_at.nil?) && (self.spot_open_till > Time.now)
  end
  
  def spot_open_till
    return self.spot_opened_at + Setting.wait_list_opening_window.to_f.hours unless self.spot_opened_at.nil?
    return nil
  end
  
  def spot_number
    return WaitListReservation.count(["bus_id = ? AND spot_opened_at IS NULL AND created_at < ?", self.bus_id, self.created_at]) + 1
  end
end
