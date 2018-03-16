class IndexController < ApplicationController
  before_action :load_user_if_logged_in

  def index
    a = 1
    if !@user.nil?
      if session[:wait_list_id].present?
        redirect_to :controller => "reservations", :action => "get_on_wait_list", :id => session[:wait_list_id]
      else
        render
      end
    end
  end

  def about
  end

  def group_tickets
  end

  def help
  end
end
