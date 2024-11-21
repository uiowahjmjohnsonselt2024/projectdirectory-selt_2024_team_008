class MysteryBoxesController < ApplicationController
  def open
    # Logic for rendering the opening page
    @mystery_box_count = current_user.user_items.find_by(item: Item.find_by(item_name: "Mystery Box"))&.quantity || 0

    def open_box
      mystery_box = current_user.user_items.find_by(item: Item.find_by(item_name: "Mystery Box"))

      if mystery_box && mystery_box.quantity > 0
        mystery_box.update(quantity: mystery_box.quantity - 1)
        render json: { success: true, remaining_boxes: mystery_box.quantity }
      else
        render json: { success: false, message: "No mystery boxes remaining." }
      end
    end
  end
end