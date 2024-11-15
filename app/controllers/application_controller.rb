# frozen_string_literal: true

# ApplicationController is the base controller from which all other controllers inherit.
# It can contain filters, exception handling, and other shared logic for controllers.
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Configure additional parameters for Devise
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!, except: [:home]

  protected

  # Permit additional parameters for Devise (e.g., email and password for sign up)
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :email, :password, :password_confirmation])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login, :password])
    devise_parameter_sanitizer.permit(:account_update, keys: [:email, :password, :password_confirmation, :current_password])
  end

  # def after_sign_in_path_for(resource)
  #   # Redirect to the desired page, e.g., user profile or dashboard
  #   # user_dashboard_path # or any other path you want
  # end
  #
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end
