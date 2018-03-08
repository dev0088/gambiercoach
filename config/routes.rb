Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  # get '/admin', :controller => "admin", :action => "index"
  # get '/', :controller => "admin", :action => "edit_2007_2008_schedule"
  # get ':controller/:action', :controller => "index"
  # match ':controller/:action/:id', via: [:get, :post]

  resources :admins
  resources :administrators do
    collection do
      get :login
    end
  end
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
  resources :index do
    collection do
      get :schedule_for_2007_2008
    end
  end
  get "/", :controller => "index", :action => "schedule_for_2007_2008"

end
