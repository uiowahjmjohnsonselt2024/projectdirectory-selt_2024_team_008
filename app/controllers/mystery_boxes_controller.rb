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

      random_item = Item.where.not(item_name: "Mystery Box").order("RANDOM()").first

      user_item = current_user.user_items.find_or_initialize_by(item: random_item)
      user_item.quantity ||= 0
      user_item.quantity += 1
      user_item.save

      render json: { success: true, item_name: random_item.item_name, item_image_url: view_context.asset_path(random_item.images), remaining_boxes: mystery_box.quantity }
    else
      render json: { success: false, message: "No mystery boxes remaining." }
    end
  end

  def purchase
    cost = 10
    shard_account = current_user.shard_account

    if shard_account.balance >= cost
      mystery_box = Item.find_by(item_name: "Mystery Box")

      if mystery_box
        ActiveRecord::Base.transaction do
          # Deduct shards
          shard_account.update!(balance: shard_account.balance - cost)

          # Find or create a user_item for the Mystery Box
          user_item = current_user.user_items.find_or_initialize_by(item: mystery_box)
          user_item.quantity = (user_item.quantity || 0) + 1
          user_item.save!
        end

        flash[:notice] = "You have successfully purchased a Mystery Box!"
        redirect_to shop_index_path
      else
        Rails.logger.error("Failed to find Mystery Box item")
        flash[:alert] = "There was an issue purchasing the Mystery Box."
        redirect_back(fallback_location: root_path)
      end
    else
      flash[:alert] = "You do not have enough Shards to purchase a Mystery Box."
      redirect_back(fallback_location: root_path)
    end
  end
end
