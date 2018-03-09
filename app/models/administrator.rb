require 'digest/sha1'
# # require 'ajax_scaffold'

class Administrator < ActiveRecord::Base
  attr_accessor :new_password

  before_destroy :cannot_destroy_superuser_admin
  after_validation :encrypt_new_password

  validates_uniqueness_of :username
  validates_length_of :new_password, :minimum => 5, :on => :create
  validates_length_of :new_password, :minimum => 5, :on => :update, :allow_nil => true
  validates_length_of :email, :minimum => 3

  # @scaffold_columns = [
  #   AjaxScaffold::ScaffoldColumn.new(self, {:name => "username",
  #                                           :label => "Username"}),
  #   AjaxScaffold::ScaffoldColumn.new(self, {:name => "email",
  #                                           :label => "Email"})
  # ]

  def self.authenticate(username, pass)
    puts "======== #{__callee__}:#{__LINE__}:#{__FILE__}: #{username}, #{pass}"

    u = where("username = ?", username).first
    return nil if u.nil?
    puts "======== #{__callee__}:#{__LINE__}:#{__FILE__}: #{username}, #{pass}"
    where("username = ? AND salted_password = ?",
      username, Administrator.salted_password(u.salt,
                  Administrator.hashed(pass))
    ).first
  end

  def generate_reset_password_token
    write_attribute('reset_password_token', Administrator.hashed(self.salted_password + Time.now.to_i.to_s + rand.to_s))
    udpate
    return self.reset_password_token
  end

  def superuser?
    return self.superuser == 1
  end

  private

  def self.hashed(str)
    return Digest::SHA1.hexdigest("replace-this-salt--#{str}--}")[0..39]
  end

  def self.salted_password(salt, hashed_password)
    hashed(salt + hashed_password)
  end

  def encrypt_new_password
    if !self.new_password.nil?
      self.salt = Administrator.hashed("salt-#{Time.now}")
      self.salted_password = Administrator.salted_password(self.salt, Administrator.hashed(self.new_password))
      self.new_password = nil
    end
  end

  def cannot_destroy_superuser_admin
    if self.username == "admin"
      raise "cannot delete the superuser admin"
    end
  end
end
