# app/controllers/errors_controller.rb

class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:handle_invalid_route]

  def handle_invalid_route
    if user_signed_in?
      redirect_to main_menu_path, alert: 'You were redirected to the main menu because the page does not exist.'
    else
      redirect_to root_path, alert: 'You need to sign in to continue.'
    end
  end
end