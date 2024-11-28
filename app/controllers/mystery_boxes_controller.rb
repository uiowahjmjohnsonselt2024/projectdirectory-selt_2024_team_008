class MysteryBoxesController < ApplicationController
  before_action :authenticate_user! # Ensure the user is logged in

  def open
    # Fetch the user's mystery box count for rendering the opening page
    mystery_box = current_user.user_items.find_by(item: Item.find_by(item_name: "Mystery Box"))
    @mystery_box_count = mystery_box&.quantity || 0
  end

  def open_box
    # Fetch the mystery box item from the user's inventory.css
    mystery_box = current_user.user_items.find_by(item: Item.find_by(item_name: "Mystery Box"))

    if mystery_box && mystery_box.quantity > 0
      mystery_box.update(quantity: mystery_box.quantity - 1)

      random_item = Item.order("RANDOM()").first

      user_item = current_user.user_items.find_or_initialize_by(item: random_item)
      user_item.quantity ||= 0
      user_item.quantity += 1
      user_item.save

      render json: { success: true, item_name: random_item.item_name, remaining_boxes: mystery_box.quantity }
    else
      render json: { success: false, message: "No mystery boxes remaining." }
    end
  end
end
