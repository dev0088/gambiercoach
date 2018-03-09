Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
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
  resources :index, only: [:index]
  resources :manager do
    collection do
      get :bus
      get :create_edit_user
      get :system_reset_options
      get :email_bus
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
      get :send_user_forgot_password
      get :unpaid_walkons
      post :unpaid_walkons
      get :walkons_csv
      get :all_reservations_csv
      get :session_tickets_csv
      get :unpaid_reservations
      post :unpaid_reservations
      get :trip_report
      post :trip_report
      get :users
      post :users
    end
  end
  resources :reservations do
    get :student_conductor_terms
    get :complete
    get :my_reservations
    get :my_wait_list_reservations
    get :get_on_wait_list
    get :cancel_wait_list_reservation
    get :modify
    post :modify
    get :process_cc
    get :process_cash
    get :reserve_tickets
  end
  resources :routes do
    get :return_to_main
    get :list
    get :component_update
    get :component
    get :cancel
  end
  resources :settings do
    get :return_to_main
    get :list
    get :component_update
    get :component
    get :edit_settings
    post :edit_settings
    get :cancel
  end
  resources :stored_address do
    post :delete
  end
  resources :transport_sessions do
    get :return_to_main
    get :component_update
    get :component
    get :cancel
  end
  resources :user do
    collection do
      get :login
      post :login
      post :verify
      get :complete_verify
      get :logout
      get :change_password
      post :change_password
      get :change_forgot_password
      post :change_forgot_password
      get :forgot_password
      get :sent_forgot_password_link
    end
  end

  get "/", :controller => "index", :action => "index"
  get "/group_tickets", :controller => "index", :action => "group_tickets"
  get "/help", :controller => "index", :action => "help"
  get "/about", :controller => "index", :action => "about"
end
