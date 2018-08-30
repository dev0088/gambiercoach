class AdministratorsController < ApplicationController
  # include AjaxScaffold::Controller
  layout "admin"

  before_action :admin_login_required, :except => [:login, :forgot_password, :reset_password]
  # after_action :clear_flashes

  def login
    case request.method
    when 'GET'
      render
      return
    when 'POST'
      admin = Administrator.authenticate(params[:username], params[:password])
      if admin != nil
        flash[:success] = "welcome, #{admin.username}"
        session[:admin_id] = admin.id
        redirect_to :controller => "admin", :action => "index"
        return
      else
        flash.now[:error] = "please re-check your username and password"
        render
        return
      end
    end
  end

  def logout
    session[:admin_id] = nil
    flash[:success] = "you successfully logged out"
    redirect_to :action => "login"
  end

  def change_password
    case request.method
    when 'GET'
      render
      return
    when 'POST'
      admin = Administrator.where(id: session[:admin_id]).first
      if params[:new_password] != params[:repeat_new_password]
        flash.now[:error] = "your entered passwords did not match, please try again"
        render
        return
      else
        admin.new_password = params[:new_password]
        if admin.save
          flash[:success] = "saved your new password"
          redirect_to :controller => "admin", :action => "index"
          return
        else
          if admin.errors.empty?
            flash.now[:error] = "we encountered a problem, please try again"
          else
            flash.now[:error] = ""
            admin.errors.full_messages.each do |e|
              flash.now[:error] += e + "\n"
            end
          end
          render
          return
        end
      end
    end
  end

  def forgot_password
    # Always redirect if logged in
    if !session[:admin_id].nil?
      flash[:error] = "you are already logged in.\nIf you forgot your password and want to reset it, log out and then click 'forgot password' on the log in page."
      redirect_to :controller => "admin", :action => "index"
      return
    end

    # Render on GET
    if request.method == 'GET'
      render
      return
    end

    # Handling a POST from here on out...

    # Did they not enter an email/username?
    if !params[:username].present?
      flash.now[:error] = 'please enter a username.'
      render
      return
    end

    # Did they enter a potential username?
    admin = Administrator.where("username = ?", params["username"]).first

    # If the search turned up nil, we'll send the user back to try again.
    # Otherwise, we'll send them a change_password URL and notify them of that...
    if admin.nil?
      flash.now[:error] = "we could not find an administrator with that username, please try again."
      render
      return
    else
      key = admin.generate_reset_password_token
      url = url_for(:action => 'change_password', :admin_id => admin.id, :auth_token => key)
      # AdminNotify.forgot_password(user, url).deliver_later
      flash[:success] = "emailed instructions for setting a new password to #{admin.email}.\nPlease follow the instructions in that email. Thank you."
      render
      return
    end
  end

  def reset_password

  end

  def index
    @sort_sql = Administrator.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{Administrator.table_name}.#{Administrator.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)
    @administrators = Administrator.order(@sort_by).paginate(page: 1, :per_page => 25)
    @new_administrator = Administrator.new
  end


  def return_to_main
    # If you have multiple scaffolds on the same view then you will want to change this to
    # to whatever controller/action shows all the views
    # (ex: redirect_to :controller => 'AdminConsole', :action => 'index')
    redirect_to :action => 'index'
  end

  def list
  end

  # All posts to change scaffold level variables like sort values or page changes go through this action
  def component_update
    if request.xhr?
      # If this is an AJAX request then we just want to delegate to the component to rerender itself
      component
    else
      # If this is from a client without javascript we want to update the session parameters and then delegate
      # back to whatever page is displaying the scaffold, which will then rerender all scaffolds with these update parameters
      update_params :default_scaffold_id => "administrator", :default_sort => nil, :default_sort_direction => "asc"
      return_to_main
    end
  end

  def component
    update_params :default_scaffold_id => "administrator", :default_sort => nil, :default_sort_direction => "asc"

    @sort_sql = Administrator.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{Administrator.table_name}.#{Administrator.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)
    @paginator, @administrators = paginate(:administrators, :order => @sort_by, :per_page => 25)

    render :action => "component", :layout => false
  end

  def new
    @administrator = Administrator.new
    @successful = true

    return render :action => 'new.rjs' if request.xhr?

    # Javascript disabled fallback
    if @successful
      @options = { :action => "create" }
      render :partial => "new_edit", :layout => true
    else
      return_to_main
    end
  end

  def create
    begin
      @administrator = Administrator.new(craete_administrator_params)
      @successful = @administrator.save
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    if !@successful
      @options = { :scaffold_id => params[:controller], :action => "create" }
    end
    redirect_to '/administrators'
  end

  def edit
    begin
      @administrator = Administrator.find(params[:id])
      @successful = !@administrator.nil?
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    return render :action => 'edit.rjs' if request.xhr?

    if @successful
      @options = { :scaffold_id => params[:controller], :action => "update", :id => params[:id] }
      render :partial => 'new_edit', :layout => true
    else
      return_to_main
    end
  end

  def update_administrator
    begin
      @administrator = Administrator.find(params[:id])
      @successful = @administrator.update_attributes(update_administrator_params)
      result = @administrator.to_json
      status_code = 200
    rescue
      flash[:error], @successful  = $!.to_s, false
      result = {message: flash[:error]}
      status_code = 403
    end

    respond_to do |format|
      format.html {redirect_to "/administrators"}
      format.json { render status: status_code, json: result }
    end
  end

  def update
    begin
      @administrator = Administrator.find(params[:id])
      if params[:administrator][:new_password] == ""
        params[:administrator][:new_password] = nil
      end
      @successful = @administrator.update_attributes(params[:administrator])
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    return render :action => 'update.rjs' if request.xhr?

    if @successful
      return_to_main
    else
      @options = { :action => "update" }
      render :partial => 'new_edit', :layout => true
    end
  end

  def destroy
    begin
      @successful = Administrator.find(params[:id]).destroy
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    # Javascript disabled fallback
    return_to_main
  end

  def cancel
    @successful = true

    return render :action => 'cancel.rjs' if request.xhr?

    return_to_main
  end
end

private
def update_administrator_params
  params[:administrator][:new_password] = nil if params[:administrator][:new_password] == ""
  administrator_params = params[:administrator]
  params.require(:administrator)
        .permit(:username, :email, :new_password)
end

def craete_administrator_params
  params[:administrator][:new_password] = "default" if !params[:administrator][:new_password].present?
  administrator_params = params[:administrator]
  administrator_params[:superuser] = 0
  params.require(:administrator)
        .permit(:username, :email, :superuser, :new_password)
end
