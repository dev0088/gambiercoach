module ApplicationHelper
  def my_reservations_count_helper
    @user.reservations.count
  end

  def my_waiting_lists_count_helper
    @user.wait_list_reservations.where("(spot_opened_at IS NULL) OR (spot_opened_at > ?)", Setting.earliest_valid_wait_list_opening).count
  end
end
