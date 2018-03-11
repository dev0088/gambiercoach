module AdminLibrary

def admin_login_required
  if !session[:admin_id].nil?
    @admin = Administrator.find(session[:admin_id])
    return true
  end

  # call overwriteable reaction to unauthorized access
  redirect_to :controller => "administrators", :action => "login"
  return false 
end

end