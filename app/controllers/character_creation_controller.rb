class CharacterCreationController < ApplicationController
  def index
    @avatar = current_user.avatar
    @user_items = current_user.user_items.includes(:item)
  end
end
