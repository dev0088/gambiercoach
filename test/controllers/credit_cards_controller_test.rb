require 'test_helper'

class CreditCardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @credit_card = credit_cards(:one)
  end

  test "should get index" do
    get credit_cards_url
    assert_response :success
  end

  test "should get new" do
    get new_credit_card_url
    assert_response :success
  end

  test "should create credit_card" do
    assert_difference('CreditCard.count') do
      post credit_cards_url, params: { credit_card: { exp_mo: @credit_card.exp_mo, exp_year: @credit_card.exp_year, kind: @credit_card.kind, last_4: @credit_card.last_4, stripe_card_id: @credit_card.stripe_card_id, user_id: @credit_card.user_id } }
    end

    assert_redirected_to credit_card_url(CreditCard.last)
  end

  test "should show credit_card" do
    get credit_card_url(@credit_card)
    assert_response :success
  end

  test "should get edit" do
    get edit_credit_card_url(@credit_card)
    assert_response :success
  end

  test "should update credit_card" do
    patch credit_card_url(@credit_card), params: { credit_card: { exp_mo: @credit_card.exp_mo, exp_year: @credit_card.exp_year, kind: @credit_card.kind, last_4: @credit_card.last_4, stripe_card_id: @credit_card.stripe_card_id, user_id: @credit_card.user_id } }
    assert_redirected_to credit_card_url(@credit_card)
  end

  test "should destroy credit_card" do
    assert_difference('CreditCard.count', -1) do
      delete credit_card_url(@credit_card)
    end

    assert_redirected_to credit_cards_url
  end
end
