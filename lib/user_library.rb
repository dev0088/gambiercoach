module UserLibrary

# Used as a before_action for actions that require
# a logged-in user.
def login_required
  if user?
    @user = current_user
    return true
  end

  # store current location so that we can
  # come back after the user logged in
  store_location
  # receiver may overwrite this re-direct, but the home page should be the default landing point
  redirect_to :controller => "user", :action => "login"
  return false
end

# Used as a before_action for action that do not require
# a logged-in user, but would like to "use" the user if
# they *are* logged in... :)
def load_user_if_logged_in
  if user?
    @user = current_user
  else
    @user = nil
  end
  return true
end

# store current uri in  the session.
def store_location
  session['return-to'] = request.request_uri
end

# move to the last store_location call or to the passed default one
def redirect_to_stored_or_default(default)
  if session['return-to'].nil?
    redirect_to default
  else
    redirect_to_url session['return-to']
    session['return-to'] = nil
  end
end

# move to the previous location or to the passed default one
def redirect_back_or_default(default)
  if request.env["HTTP_REFERER"].nil?
    redirect_to default
  else
    redirect_to(request.env["HTTP_REFERER"]) # same as redirect_to :back
  end
end

# checks to see if a user is logged in either by the session or by a
# remember-me token ... and loads the user into the session if they are
# returning with a remember-me token.
def user?
  # First, is the user already authenticated?
  return true if !current_user_id.nil?

  # If not, is the user using a remember-me token?
  remember_me_token = cookies[:transport_remember_me_token]
  if !remember_me_token.nil?
    user_id, token = remember_me_token.split("_t_",2)
    new_token = User.authenticate_by_remember_me(user_id, token)
    if !new_token.nil?
      user = User.where("id = ?", user_id).first
      if user.nil?
        return false
      end
      user.save
      cookies[:transport_remember_me_token] = {:value => user_id + "_t_" + new_token, :expires => Time.now + 1.week}
      session[:user_id] = user.id
      return true
    end
  end

  # Everything failed
  return false
end

# Returns the current user from the session, if any exists
def current_user
  return nil if current_user_id.nil?
  User.where(id: current_user_id).first
end

def current_user_id
  session[:user_id]
end

end
