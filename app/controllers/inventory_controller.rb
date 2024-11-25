class InventoryController < ApplicationController
  def show
    @user_items = current_user.user_items.includes(:item)
  end
end
