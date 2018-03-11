class WalkOn < ActiveRecord::Base
  belongs_to :bus
  WalkOn::UNPAID = 0
  WalkOn::PAID = 1
end
