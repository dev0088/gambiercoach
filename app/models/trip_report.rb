class TripReport < ActiveRecord::Base
  belongs_to :user
  belongs_to :bus
  before_create 'self.created_at = Time.now'
  after_create 'self.bus.update_attribute(:report_token, nil)'
  
  def self.setup(bus)
    bus.report_token = Digest::SHA1.hexdigest("#{Time.now}#{bus.id.to_s}#{bus.departure.to_s}#{rand(10000000000).to_s}")[0...30]
    while(!Bus.find_by_report_token(bus.report_token).nil?)
      bus.report_token = Digest::SHA1.hexdigest("#{Time.now}#{bus.id.to_s}#{bus.departure.to_s}#{rand(10000000000).to_s}")[0...30]
    end
    bus.save!
  end
  
  def self.url(bus)
    return Setting::SERVER_URL + "/manager/trip_report/" + bus.report_token
  end
end
