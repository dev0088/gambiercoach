require 'digest/sha1'

class RememberMeToken < ActiveRecord::Base
  def RememberMeToken.authenticate(user_id, token)
    succ = delete_all(["user_id = ? and token = ?", user_id, token])
    if succ == 1
      return RememberMeToken.generate(user_id)
    else
      return nil
    end
  end
  
  def RememberMeToken.generate(user_id)
    token = Digest::SHA1.hexdigest("#{Time.now.to_s}--#{user_id.to_s}")[0..39]
    create(:user_id => user_id,
           :token => token,
           :expires => Time.now + 1.week)
    return token
  end
end