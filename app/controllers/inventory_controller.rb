class InventoryController < ApplicationController
  before_action :authenticate_user!
  def show
    @user_items = current_user.user_items.includes(:item)
    @origin = params[:origin]
  end
end
