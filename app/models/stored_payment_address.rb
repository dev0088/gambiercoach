class StoredPaymentAddress < ActiveRecord::Base
  belongs_to :user
end
