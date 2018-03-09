class Initial < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.column :session_id, :string
      t.column :data, :text
      t.column :updated_at, :datetime
    end
    add_index :sessions, :session_id
    
    create_table :users do |t|
      t.column :login_id, :string, :null => false
      t.column :reset_password_token, :string, :limit => 40
      t.column :phone, :string, :limit => 12
      t.column :salted_password, :string, :limit => 40, :default => nil
      t.column :salt, :string, :limit => 40, :null => false
      t.column :verified, :integer, :default => 0
    end
    
    create_table :stored_payment_addresses do |t|
      t.column :user_id, :integer, :null => false
      t.column :name_on_card, :string, :limit => 100
      t.column :address_one, :string, :limit => 100
      t.column :city, :string, :limit => 100
      t.column :state, :string, :limit => 100
      t.column :zip, :string, :limit => 100
    end
    
    create_table "remember_me_tokens" do |t|
      t.column "user_id", :integer, :null => false
      t.column "token", :string, :limit => 40, :null => false
      t.column "expires", :datetime, :null => false
    end
    
    create_table :administrators do |t|
      t.column :username, :string, :null => false
      t.column :salted_password, :string, :limit => 40, :null => false
      t.column :salt, :string, :limit => 40, :null => false
      t.column :superuser, :integer, :default => 0, :null => false
      t.column :reset_password_token, :string, :limit => 40
      t.column :email, :string, :limit => 40, :null => false
    end
    
    Administrator.create(:username => "admin",
                         :new_password => "default",
                         :superuser => 1,
                         :email => "joe@wtown.org")
    
    create_table :transport_sessions do |t|
      t.column :name, :string, :limit => 40, :null => false
      t.column :reservations_opening_date, :datetime
      t.column :session_closing_date, :datetime
      t.column :cash_reservations_closing_date, :datetime
      t.column :cash_reservations_information, :text
    end
    
    create_table :routes do |t|
      t.column :transport_session_id, :integer, :null => false
      t.column :point_a, :string, :limit => 40, :null => false
      t.column :point_b, :string, :limit => 40, :null => false
      t.column :information, :text
      t.column :price, :string
      t.column :display_order, :integer
    end
    
    create_table :buses do |t|
      t.column :route_id, :integer, :null => false
      t.column :going_away, :boolean, :null => false
      t.column :departure, :datetime, :null => false
      t.column :seats, :integer, :null => false
      t.column :occupied_seats, :integer, :null => false, :default => 0
      t.column :reservations_closing_date, :datetime, :null => false
    end
    
    create_table :wait_list_reservations do |t|
      t.column :bus_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :created_at, :datetime, :null => false
      t.column :spot_open_till, :datetime, :default => nil
    end
    
    create_table :reservations do |t|
      t.column :user_id, :integer, :null => false
      t.column :created_at, :datetime, :null => false
      t.column :last_modified_at, :datetime, :null => false
      t.column :payment_status, :integer, :null => false
      t.column :payment_note, :string, :limit => 100
      t.column :total, :string
    end
    
    create_table :credit_payment_events do |t|
      t.column :user_id, :integer, :null => false
      t.column :reservation_id, :integer
      t.column :transaction_amt, :string
      t.column :response_code, :integer, :null => false
      t.column :transaction_type, :integer, :null => false
      t.column :transaction_id, :integer
      t.column :error_code, :integer
      t.column :error_message, :string, :limit => 50
      t.column :authorization, :string, :limit => 6
      t.column :avs_code, :string, :limit => 1
      t.column :cvv2_response, :string, :limit => 1
      t.column :cavv_response, :string, :limit => 1
      t.column :created_at, :datetime, :null => false
      t.column :cc_last_four, :string, :limit => 4
    end
    
    create_table :reservation_tickets do |t|
      t.column :reservation_id, :integer, :null => false
      t.column :bus_id, :integer, :null => false
      t.column :quantity, :integer, :null => false
      t.column :conductor_wish, :integer, :null => false, :default => 0
      t.column :conductor_status, :integer, :null => false, :default => 0
    end
        
    create_table :settings do |t|
      t.column :reservations_closing_time, :time
      t.column :max_tickets_purchase, :integer
    end
  end

  def self.down
  end
end
