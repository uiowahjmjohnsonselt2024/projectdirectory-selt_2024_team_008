# frozen_string_literal: true

# ApplicationController is the base controller from which all other controllers inherit.
# It can contain filters, exception handling, and other shared logic for controllers.
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
end
