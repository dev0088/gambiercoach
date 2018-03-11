class StoredAddressController < ApplicationController
  before_action :login_required

  def edit
    @spa = @user.stored_payment_addresses.find(params[:id])
    case request.method
    when 'POST'
      @spa.name_on_card = params[:name_on_card]
      @spa.address_one = params[:address_one]
      @spa.city = params[:city]
      @spa.state = params[:state]
      @spa.zip = params[:zip]
      @spa.save
      redirect_to :controller => "reservations", :action => "create"
    when 'GET'
      render
      return
    end
  end

  def delete
    case request.method
    when 'POST'
      @spa = @user.stored_payment_addresses.find(params[:id])
      @spa.destroy
      redirect_to :controller => "reservations", :action => "create"
      return
    end
  end
end
