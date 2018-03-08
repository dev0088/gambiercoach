class IndexController < ApplicationController
  before_action:load_user_if_logged_in
end
