require 'test_helper'

class StripeEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @stripe_event = stripe_events(:one)
  end

  test "should get index" do
    get stripe_events_url
    assert_response :success
  end

  test "should get new" do
    get new_stripe_event_url
    assert_response :success
  end

  test "should create stripe_event" do
    assert_difference('StripeEvent.count') do
      post stripe_events_url, params: { stripe_event: { error: @stripe_event.error, kind: @stripe_event.kind, stripe_event_id: @stripe_event.stripe_event_id } }
    end

    assert_redirected_to stripe_event_url(StripeEvent.last)
  end

  test "should show stripe_event" do
    get stripe_event_url(@stripe_event)
    assert_response :success
  end

  test "should get edit" do
    get edit_stripe_event_url(@stripe_event)
    assert_response :success
  end

  test "should update stripe_event" do
    patch stripe_event_url(@stripe_event), params: { stripe_event: { error: @stripe_event.error, kind: @stripe_event.kind, stripe_event_id: @stripe_event.stripe_event_id } }
    assert_redirected_to stripe_event_url(@stripe_event)
  end

  test "should destroy stripe_event" do
    assert_difference('StripeEvent.count', -1) do
      delete stripe_event_url(@stripe_event)
    end

    assert_redirected_to stripe_events_url
  end
end
