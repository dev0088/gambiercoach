json.extract! credit_card, :id, :user_id, :last_4, :kind, :exp_mo, :exp_year, :stripe_card_id, :created_at, :updated_at
json.url credit_card_url(credit_card, format: :json)
