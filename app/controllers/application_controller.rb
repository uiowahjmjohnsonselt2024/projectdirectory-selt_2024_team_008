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
  before_action :store_user_id_in_cookies

  protected

  # Permit additional parameters for Devise (e.g., email and password for sign up)
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[username email password password_confirmation])
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[login password])
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: %i[email password password_confirmation current_password])
  end

   def after_sign_in_path_for(resource)
     # Redirect to the desired page, e.g., user profile or dashboard
     main_menu_path
   end
  
  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end

  def redirect_to_main_menu
    if user_signed_in?
      redirect_to main_menu_path, alert: 'You were redirected to the main menu because the page does not exist or you do not have access.'
    else
      redirect_to root_path, alert: 'You need to sign in or sign up before continuing.'
    end
  end

  private

  def store_user_id_in_cookies
    if user_signed_in?
      cookies.signed[:user_id] = current_user.id if current_user
    end
  end

end