class ApplicationController < ActionController::Base
  include UserLibrary
  include AdminLibrary
  # include SslRequirement

  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
  # before_action :force_ssl, :only => [:login]
  after_action :return_errors, only: [:page_not_found, :server_error]

  Rails.application.config.filter_parameters += [:password]
  Rails.application.config.filter_parameters += [:card_number]
  Rails.application.config.filter_parameters += [:expiration_month]
  Rails.application.config.filter_parameters += [:expiration_month]
  Rails.application.config.filter_parameters += [:expiration_year]
  Rails.application.config.filter_parameters += [:name_on_card]

  def page_not_found
    @status = 404
    @layout = "application"
    # @template = "not_found_error"
    @template = "promote"
  end

  def server_error
     @status = 500
     @layout = "error"
     # @template = "internal_server_error"
     @template = "promote"
  end

  def force_ssl(options = {})
    host = options.delete(:host)
    unless request.ssl? or Rails.env.development?
      redirect_options = {:protocol => 'https://', :status => :moved_permanently}
      redirect_options.merge!(:host => host) if host
      flash.keep
      redirect_to redirect_options and return
    else
      true
    end
  end

  def parse_schedule_selections(selections)
    reservations = []
    price = Money.new(0)
    cash_reservations_allowed = true
    selections.each do |p|
      if (p =~ /^[0-9]+$/).present?
        if selections[p].to_i > 0
          # bus = Bus.find(p[0])
          bus = Bus.find(p)
          reservations << [bus, selections[p].to_i]
          if !bus.cash_reservations_allowed?
            cash_reservations_allowed = false
          end
          price = price + (bus.to_m * selections[p].to_i)
        end
      end
    end
    return reservations, price, cash_reservations_allowed
  end

  private

 def return_errors
   respond_to do |format|
         format.html { render template: 'errors/' + @template, layout: 'layouts/' + @layout, status: @status }
         format.all  { render nothing: true, status: @status }
   end
 end
end
