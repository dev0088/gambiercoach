require 'digest/sha1'

class User < ActiveRecord::Base
  has_many :stored_payment_addresses, :dependent => :destroy
  has_many :reservations
  has_many :wait_list_reservations
  has_many :credit_payment_events
  has_many :trip_reports
  attr_accessor :new_password
  after_validation :encrypt_new_password


  def validate  
    u = User.find(:first, :conditions => ["login_id = ?", self.login_id])
    if !u.nil?
      if (self.new_record?) || (self.id != u.id)
        self.errors.add_to_base("the login id you supplied was already registered, please log in or click 'forgot password'")
        return
      end
    end

    # new password is of correct length
    if !self.new_password.nil? && !(5..100).include?(self.new_password.length)
      self.errors.add_to_base("your password must be between 5 and 100 characters long (numbers, letters, punctuation all OK)")
      return
    end    
  end
  
  def correct_password?(pass)
    return self.salted_password == User.salted_password(self.salt, User.hashed(pass))
  end

  # Class Methods
  def User.authenticate(login_id, pass)
    u = find(:first, :conditions => ["login_id = ? AND verified = 1", login_id])
    return nil if u.nil?
    find(:first, :conditions => ["login_id = ? AND salted_password = ? AND verified = 1", login_id, User.salted_password(u.salt, User.hashed(pass))])
  end

  def User.authenticate_by_reset_password_token(id, token)
    u = find(:first, :conditions => ["id = ? AND reset_password_token = ?", id, token])
    return nil if u.nil? or u.token_expired?
    return nil if false == u.update_expiry
    u
  end

  def User.authenticate_by_remember_me(id, token)
    RememberMeToken.authenticate(id, token)
  end
  
  def User.invalidate_token(complete_token)
    user_id, token = complete_token.split("_t_")
    RememberMeToken.delete_all(["user_id = ? and token = ?", user_id, token])
  end

  def set_remember_me
    RememberMeToken.generate(self.id)
  end
  
  def generate_reset_password_token
    write_attribute('reset_password_token', User.hashed(Time.now.to_i.to_s + rand.to_s))
    update_without_callbacks
    return self.reset_password_token
  end

  def change_password(new_password, password_confirmation)
    # confirm that both passwords the user entered match
    if new_password != password_confirmation
      self.errors.add_to_base("new password and password confirmation did not match -- you must enter the new password in both fields identically")
      return
    end
    
    self.new_password = new_password
    self.save
    return self
  end
  
  def email
    if self.login_id =~ /^.+@.+\..+$/
      return login_id
    else
      return login_id + Setting::EMAIL
    end
  end
  
  def must_change_password?
    return (self.must_change_password == 1)
  end
  
  def on_wait_list_for?(bus_id)
    return !WaitListReservation.find(:first, :conditions => ["user_id = ? and bus_id = ?", self.id, bus_id]).nil?
  end
  
  protected

  def self.hashed(str)
    return Digest::SHA1.hexdigest("replace-this-salt--#{str}--}")[0..9]
  end

  def self.salted_password(salt, hashed_password)
    hashed(salt + hashed_password)
  end
  
  def encrypt_new_password
    if !self.new_password.nil?
      self.salt = User.hashed("salt-#{Time.now}")
      self.salted_password = User.salted_password(self.salt, User.hashed(self.new_password))
      self.new_password = nil
    end
  end
end

