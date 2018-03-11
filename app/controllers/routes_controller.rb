class RoutesController < ApplicationController
  # include AjaxScaffold::Controller
  layout "admin"

  before_action :admin_login_required
  # after_action :clear_flashes

  def index
    # redirect_to :action => 'list'
    @sort_sql = Route.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{Route.table_name}.#{Route.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)
    @routes = Route.order(@sort_by).paginate(page: 1, :per_page => 25)
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
      update_params :default_scaffold_id => "route", :default_sort => nil, :default_sort_direction => "asc"
      return_to_main
    end
  end

  def component
    update_params :default_scaffold_id => "route", :default_sort => nil, :default_sort_direction => "asc"

    @sort_sql = Route.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{Route.table_name}.#{Route.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)
    @paginator, @routes = paginate(:routes, :order => @sort_by, :per_page => 25, :include => :transport_session)

    render :action => "component", :layout => false
  end

  def new
    @route = Route.new
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
      @route = Route.new(params[:route])
      @successful = @route.save
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    return render :action => 'create.rjs' if request.xhr?
    if @successful
      return_to_main
    else
      @options = { :scaffold_id => params[:controller], :action => "create" }
      render :partial => 'new_edit', :layout => true
    end
  end

  def edit
    begin
      @route = Route.find(params[:id])
      @successful = !@route.nil?
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

  def update
    begin
      @route = Route.find(params[:id])
      @successful = @route.update_attributes(params[:route])
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
      @successful = Route.find(params[:id]).destroy
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
