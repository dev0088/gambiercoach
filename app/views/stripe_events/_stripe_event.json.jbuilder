json.extract! stripe_event, :id, :stripe_event_id, :kind, :error, :created_at, :updated_at
json.url stripe_event_url(stripe_event, format: :json)
