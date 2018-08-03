Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "/", :controller => "index", :action => "index"
  get "/group_tickets", :controller => "index", :action => "group_tickets"
  get "/help", :controller => "index", :action => "help"
  get "/about", :controller => "index", :action => "about"

  get "/reservations/my_reservations", :controller => "reservations", :action => "my_reservations"
  get "/reservations/my_wait_list_reservations", :controller => "reservations", :action => "my_wait_list_reservations"
  post "/reservations/complete", :controller => "reservations", :action => "complete"
  get "/reservations/create", :controller => "reservations", :action => "create"
  post "/reservations/create", :controller => "reservations", :action => "create"
  get "/reservations/modify/:id(.:format)", :controller => "reservations", :action => "modify"
  post "/reservations/modify/:id(.:format)", :controller => "reservations", :action => "modify"
  get "/reservations/get_on_wait_list/:id(.:format)", :controller => "reservations", :action => "get_on_wait_list"
  get "/reservations/cancel_wait_list_reservation/:id(.:format)", :controller => "reservations", :action => "cancel_wait_list_reservation"
  get "/reservations/student_conductor_terms", :controller => "reservations", :action => "student_conductor_terms"


  get "/settings/edit_settings", :controller => "settings", :action => "edit_settings"
  post "/settings/edit_settings", :controller => "settings", :action => "edit_settings"

  get "admin/edit_welcome", :controller => "admin", :action => "edit_welcome"
  post "admin/edit_welcome", :controller => "admin", :action => "edit_welcome"
  get "admin/edit_about", :controller => "admin", :action => "edit_about"
  post "admin/edit_about", :controller => "admin", :action => "edit_about"
  get "admin/edit_group_tickets", :controller => "admin", :action => "edit_group_tickets"
  post "admin/edit_group_tickets", :controller => "admin", :action => "edit_group_tickets"
  get "admin/edit_help", :controller => "admin", :action => "edit_help"
  post "admin/edit_help", :controller => "admin", :action => "edit_help"
  get "admin/email_texts", :controller => "admin", :action => "email_texts"
  post "admin/email_texts", :controller => "admin", :action => "email_texts"
  get "admin/edit_email", :controller => "admin", :action => "edit_email"
  post "admin/edit_email", :controller => "admin", :action => "edit_email"

  get "/manager/edit_reservation/:id(.:format)", :controller => "manager", :action => "edit_reservation"
  post "/manager/edit_reservation/:id(.:format)", :controller => "manager", :action => "edit_reservation"
  get "/manager/send_user_forgot_password/:id(.:format)", :controller => "manager", :action => "send_user_forgot_password"

  post "/transport_sessions/update_transport_session/:id(.:format)", :controller => "transport_sessions", :action => "update_transport_session"
  post "/routes/update_route/:id(.:format)", :controller => "routes", :action => "update_route"
  post "/buses/update_bus/:id(.:format)", :controller => "buses", :action => "update_bus"
  post "/administrators/update_administrator/:id(.:format)", :controller => "administrators", :action => "update_administrator"
  resources :admin do
    get :edit_email
    get :edit_welcome
    post :edit_welcome
    get :edit_group_tickets
    post :edit_group_tickets
    get :edit_about
    post :edit_about
    get :edit_help
    post :edit_help
  end
  resources :administrators do
    collection do
      get :login
      post :login
      get :forgot_password
      post :forgot_password
      get :logout
      get :change_password
      post :change_password
      get :reset_password
      get :return_to_main
      get :list
      get :component_update
      get :component
      get :cancel
    end
  end
  resources :buses do
    get :return_to_main
    get :list
    get :component_update
    get :component
    get :cancel
  end
  resources :index, only: [:index] do
    get :about
    get :group_tickets
    get :help
  end
  resources :manager do
    collection do
      get :bus
      get :system_reset_options
      post :system_reset_options
      post :email_bus
      get :session_conductors
      post :session_conductors
      get :session_reservations
      post :session_reservations
      get :edit_reservation
      post :edit_reservation
      get :create_reservation
      post :create_reservation
      get :create_edit_user
      post :create_edit_user
      get :find_user
      get :manage_trip_reports
      post :manage_trip_reports
      get :bus_trip_report_used_reservations
      # get :send_user_forgot_password
      get :unpaid_walkons
      post :unpaid_walkons
      post :walkons_csv
      get :all_reservations_csv
      post :session_tickets_csv
      get :unpaid_reservations
      post :unpaid_reservations
      get :trip_report
      post :trip_report
      get :users
      post :users
    end
  end
  resources :reservations do
  end

  resources :routes do
  end
  resources :settings do
  end
  resources :stored_address do
    post :delete
  end
  resources :transport_sessions do
  end
  resources :user do
    collection do
      get :login
      post :login
      get :verify
      post :verify
      get :complete_verify
      post :complete_verify
      get :logout
      get :change_password
      post :change_password
      get :change_forgot_password
      post :change_forgot_password
      get :forgot_password
      get :sent_forgot_password_link
      get :promote
    end
  end

  get '404', to: 'application#page_not_found'
  get '422', to: 'application#server_error'
  get '500', to:  'application#server_error'
  get '/promote', to: 'user#promote'
  match '*path' => redirect('/promote'), via: :get

end
