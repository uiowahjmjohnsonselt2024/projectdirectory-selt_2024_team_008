class CharacterCreationController < ApplicationController
  def index
    @avatar = current_user.avatar
    @user_items = current_user.user_items.includes(:item)
  end
  def equip_item
    avatar = current_user.avatar
    item = Item.find(params[:item_id])

    # Determine which slot to update based on the item's type
    case item.item_type
    when 'hat'
      avatar.update(hat_id: item.id)
    when 'top'
      avatar.update(top_id: item.id)
    when 'bottoms'
      avatar.update(bottoms_id: item.id)
    when 'shoes'
      avatar.update(shoes_id: item.id)
    when 'accessories'
      avatar.update(accessories_id: item.id)
    end

    # Redirect to the same page to see the updated avatar
    redirect_to character_creation_path, notice: "#{item.item_name} has been equipped!"
  end
end
