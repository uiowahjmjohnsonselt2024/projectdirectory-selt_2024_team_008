# frozen_string_literal: true

class MainMenuController < ApplicationController
  before_action :redirect_unauthorized_users

  def index
    # Render the main menu view
  end

  private

  def redirect_unauthorized_users
    unless current_user_is_user? || current_user_is_admin?
      redirect_to root_path, alert: 'You do not have access to the main menu.'
    end
  end

  def current_user_is_user?
    current_user&.role == "user"
  end

  def current_user_is_admin?
    current_user&.role == "admin"
  end
end