Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  # get '/admin', :controller => "admin", :action => "index"
  # get '/', :controller => "admin", :action => "edit_2007_2008_schedule"
  # get ':controller/:action', :controller => "index"
  # match ':controller/:action/:id', via: [:get, :post]

  resources :admins
  resources :administrators
  resources :buses
  resources :managers
  resources :reservations
  resources :settings
  resources :routes
  resources :stored_address
  resources :transport_sessions
  resources :users do
    collection do
      get :login
    end
  end

  get "/", :controller => "admin", :action => "edit_2007_2008_schedule"

end
