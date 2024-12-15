require 'rails_helper'

RSpec.describe "MysteryBoxesController", type: :feature do
  let!(:user) { User.create!(email: "test@example.com", password: "password", username: "testuser") }
  let!(:mystery_box_item) { Item.create!(item_name: "Mystery Box", item_type: "box") }
  let!(:random_item) { Item.create!(item_name: "Random Item", item_type: "reward", images: "random_item.png") }
  let!(:shard_account) { ShardAccount.create!(user: user, balance: 50) }

  before do
    login_as user, scope: :user
  end

  describe "GET #open" do
    it "renders the page and displays mystery box count" do

      UserItem.create!(user: user, item: mystery_box_item, quantity: 3)

      visit open_mystery_boxes_path
      expect(page).to have_content("3 Mystery Boxes")
    end

    it "renders the page  with zero mystery boxes if user has none" do
      visit open_mystery_boxes_path
      expect(page).to have_content("0 Mystery Boxes")
    end

    it "navigates to the shop when 'Return to Shop' is clicked" do
      visit open_mystery_boxes_path
      click_button "Return to Shop"

      expect(page).to have_current_path(shop_index_path)
    end

    it "navigates to the inventory when 'Inventory' is clicked" do
      visit open_mystery_boxes_path
      click_link "Inventory"

      expect(page).to have_current_path(inventory_path(origin: "/mystery_boxes/open"))
    end

  end

end
