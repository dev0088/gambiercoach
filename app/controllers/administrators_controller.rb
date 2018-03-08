class AdministratorsController < ApplicationController
  # include AjaxScaffold::Controller
  layout "admin"

  before_action :admin_login_required, :except => [:login, :forgot_password, :reset_password]
  # after_action :clear_flashes

  def login
    puts "=========== params: #{params.inspect}"
    case request.method
    when :get
      puts "=============="
      render
      return
    when :post
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
    when :get
      render
      return
    when :post
      admin = Administrator.find(session[:admin_id])
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
              flash.now[:error] += e + "<br />"
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
      flash[:error] = "you are already logged in.<br />If you forgot your password and want to reset it, log out and then click 'forgot password' on the log in page."
      redirect_to :controller => "admin", :action => "index"
      return
    end

    # Render on GET
    if request.method == :get
      render
      return
    end

    # Handling a POST from here on out...

    # Did they not enter an email/username?
    if params["username"].empty?
      flash.now[:error] = 'please enter a username.'
      render
      return
    end

    # Did they enter a potential username?
    admin = Administrator.find(:first, :conditions => ["username = ?", params["username"]])

    # If the search turned up nil, we'll send the user back to try again.
    # Otherwise, we'll send them a change_password URL and notify them of that...
    if admin.nil?
      flash.now[:error] = "we could not find an administrator with that username, please try again."
      render
      return
    else
      key = admin.generate_reset_password_token
      url = url_for(:action => 'change_password', :admin_id => admin.id, :auth_token => key)
      Notifications.deliver_admin_forgot_password(admin, url)
      flash[:success] = "emailed instructions for setting a new password to #{admin.email}.<br />Please follow the instructions in that email. Thank you."
      render
      return
    end
  end

  def reset_password

  end

  def index
    redirect_to :action => 'list'
  end


  def return_to_main
    # If you have multiple scaffolds on the same view then you will want to change this to
    # to whatever controller/action shows all the views
    # (ex: redirect_to :controller => 'AdminConsole', :action => 'index')
    redirect_to :action => 'list'
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
    @paginator, @administrators = paginate(:administrators, :order => @sort_by, :per_page => default_per_page)

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
      @administrator = Administrator.new(params[:administrator])
      @successful = @administrator.save
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    return render :action => 'create.rjs' if request.xhr?
    if @successful
      return_to_main
    else
      @options = { :scaffold_id => params[:scaffold_id], :action => "create" }
      render :partial => 'new_edit', :layout => true
    end
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
      @options = { :scaffold_id => params[:scaffold_id], :action => "update", :id => params[:id] }
      render :partial => 'new_edit', :layout => true
    else
      return_to_main
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

    return render :action => 'destroy.rjs' if request.xhr?

    # Javascript disabled fallback
    return_to_main
  end

  def cancel
    @successful = true

    return render :action => 'cancel.rjs' if request.xhr?

    return_to_main
  end
end
