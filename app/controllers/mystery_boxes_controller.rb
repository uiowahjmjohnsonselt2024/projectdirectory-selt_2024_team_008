class MysteryBoxesController < ApplicationController
  def open
    # Logic for rendering the opening page
    @mystery_box_count = current_user.user_items.find_by(item: Item.find_by(item_name: "Mystery Box"))&.quantity || 0

  end
end