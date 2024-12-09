class CharacterCreationController < ApplicationController
  def index
    @avatar = current_user.avatar
    @user_items = current_user.user_items.includes(:item)
  end
  def equip_item
    avatar = current_user.avatar
    item = Item.find(params[:item_id])

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

    redirect_to character_creation_path, notice: "#{item.item_name} has been equipped!"
  end

  def unequip_item
    avatar = current_user.avatar
    slot = params[:slot]

    if %w[hat top bottoms shoes accessories].include?(slot)
      avatar.update("#{slot}_id" => nil)
      redirect_to character_creation_index_path, notice: "#{slot.capitalize} has been unequipped!"
    else
      redirect_to character_creation_index_path, alert: "Invalid slot!"
    end
  end
end
