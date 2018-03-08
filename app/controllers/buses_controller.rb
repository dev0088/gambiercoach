class BusesController < ApplicationController
  # include AjaxScaffold::Controller
  layout "admin"

  before_action :admin_login_required
  # after_action :clear_flashes

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
      update_params :default_scaffold_id => "bus", :default_sort => nil, :default_sort_direction => "asc"
      return_to_main
    end
  end

  def component
    update_params :default_scaffold_id => "bus", :default_sort => nil, :default_sort_direction => "asc"

    @sort_sql = Bus.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{Bus.table_name}.#{Bus.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)
    @paginator, @buses = paginate(:buses, :order => @sort_by, :per_page => default_per_page, :include => :route)

    render :action => "component", :layout => false
  end

  def new
    @bus = Bus.new
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
      @bus = Bus.new(params[:bus])
      @successful = @bus.save
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
      @bus = Bus.find(params[:id])
      @successful = !@bus.nil?
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
      @bus = Bus.find(params[:id])
      @successful = @bus.update_attributes(params[:bus])
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
      @successful = Bus.find(params[:id]).destroy
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
