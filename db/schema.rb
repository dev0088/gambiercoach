# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190220144341) do

  create_table "administrators", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "username", default: "", null: false
    t.string "salted_password", limit: 40, default: "", null: false
    t.string "salt", limit: 40, default: "", null: false
    t.integer "superuser", default: 0, null: false
    t.string "reset_password_token", limit: 40
    t.string "email", limit: 40, default: "", null: false
  end

  create_table "buses", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "route_id", default: 0, null: false
    t.boolean "going_away", default: false, null: false
    t.datetime "departure", null: false
    t.integer "seats", default: 0, null: false
    t.integer "occupied_seats", default: 0, null: false
    t.datetime "reservations_closing_date", null: false
    t.string "report_token", limit: 40
  end

  create_table "credit_cards", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "owner_id"
    t.string "last_4"
    t.string "kind"
    t.integer "exp_mo"
    t.integer "exp_year"
    t.string "stripe_card_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "owner_type"
    t.string "token"
    t.index ["owner_id", "owner_type"], name: "index_credit_cards_on_owner_id_and_owner_type"
    t.index ["owner_id"], name: "index_credit_cards_on_owner_id"
    t.index ["stripe_card_id"], name: "index_credit_cards_on_stripe_card_id"
  end

  create_table "credit_payment_events", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "user_id", default: 0, null: false
    t.integer "reservation_id"
    t.string "transaction_amt"
    t.integer "response_code", default: 0, null: false
    t.string "transaction_type", limit: 20, default: "0", null: false
    t.integer "transaction_id"
    t.integer "error_code"
    t.string "error_message", limit: 50
    t.string "authorization", limit: 6
    t.string "avs_code", limit: 1
    t.string "cvv2_response", limit: 1
    t.string "cavv_response", limit: 1
    t.datetime "created_at", null: false
    t.string "cc_last_four", limit: 4
  end

  create_table "remember_me_tokens", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "user_id", default: 0, null: false
    t.string "token", limit: 40, default: "", null: false
    t.datetime "expires", null: false
  end

  create_table "reservation_modifications", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "reservation_id", default: 0, null: false
    t.string "modification", limit: 100
    t.datetime "created_at", null: false
    t.string "value", limit: 20
  end

  create_table "reservation_tickets", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "reservation_id", default: 0, null: false
    t.integer "bus_id", default: 0, null: false
    t.integer "quantity", default: 0, null: false
    t.integer "conductor_wish", default: 0, null: false
    t.integer "conductor_status", default: 0, null: false
  end

  create_table "reservations", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "user_id", default: 0, null: false
    t.datetime "created_at", default: "2019-02-01 00:00:00", null: false
    t.datetime "last_modified_at", default: "2020-12-21 00:00:00", null: false
    t.integer "payment_status", default: 0, null: false
    t.string "payment_note", limit: 100
    t.string "total"
    t.string "charge_id"
  end

  create_table "routes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "transport_session_id", default: 0, null: false
    t.string "point_a", limit: 40, default: "", null: false
    t.string "point_b", limit: 40, default: "", null: false
    t.text "information"
    t.string "price"
    t.integer "display_order"
  end

  create_table "schema_info", id: false, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1" do |t|
    t.integer "version"
  end

  create_table "sessions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "session_id"
    t.text "data"
    t.datetime "updated_at"
    t.index ["session_id"], name: "sessions_session_id_index"
  end

  create_table "settings", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.time "reservations_closing_time"
    t.integer "max_tickets_purchase"
    t.time "daily_payment_reminder_time"
    t.string "wait_list_opening_window", limit: 10
  end

  create_table "stored_payment_addresses", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "user_id", default: 0, null: false
    t.string "name_on_card", limit: 100
    t.string "address_one", limit: 100
    t.string "city", limit: 100
    t.string "state", limit: 100
    t.string "zip", limit: 100
  end

  create_table "stored_stripes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id"
    t.string "customer_id"
    t.integer "card_suffix"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stripe_events", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "stripe_event_id"
    t.string "kind"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transport_sessions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "name", limit: 40, default: "", null: false
    t.datetime "reservations_opening_date"
    t.datetime "session_closing_date"
    t.datetime "cash_reservations_closing_date"
    t.text "cash_reservations_information"
  end

  create_table "trip_report_used_reservations", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "bus_id"
    t.string "user_email", limit: 100
    t.integer "quantity_used"
    t.integer "reservation_ticket_id"
  end

  create_table "trip_reports", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "user_id", default: 0, null: false
    t.integer "bus_id", default: 0, null: false
    t.integer "refund_issued", default: 0
    t.integer "on_time", default: 1
    t.text "comment"
    t.datetime "created_at", null: false
  end

  create_table "users", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "login_id", default: "", null: false
    t.string "reset_password_token", limit: 40
    t.string "phone", limit: 20
    t.string "salted_password", limit: 40
    t.string "salt", limit: 40, default: "", null: false
    t.integer "verified", default: 0
    t.string "stripe_customer_id"
    t.string "charge_id"
    t.string "stripe_card_id"
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id"
  end

  create_table "wait_list_reservations", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "bus_id", default: 0, null: false
    t.integer "user_id", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "spot_opened_at"
  end

  create_table "walk_ons", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "bus_id", default: 0, null: false
    t.string "name", limit: 50
    t.string "login_id", limit: 30
    t.string "mailbox", limit: 50
    t.string "phone1", limit: 20
    t.string "phone2", limit: 20
    t.integer "payment_status", default: 0
  end

end
