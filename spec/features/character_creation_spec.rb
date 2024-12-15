require 'rails_helper'

RSpec.describe "CharacterCreationController", type: :feature do
  let!(:user) { User.create!(email: "test@example.com", password: "password", username: "testuser") }
  let!(:avatar) { Avatar.create!(user: user) }
  let!(:hat_item) { Item.create!(item_name: "Cool Hat", item_type: "hat", images: "hat.png") }
  let!(:top_item) { Item.create!(item_name: "Cool Top", item_type: "top", images: "top.png") }

  before do
    login_as user, scope: :user
  end

  describe "GET #index" do
    it "renders the character creation page" do
      visit character_creation_index_path
      expect(page).to have_button("Generate Avatar")
      expect(page).to have_css("img.character-image")
    end


    it "navigates to the shop page when 'Return to shop' is clicked" do
      visit character_creation_index_path
      click_button "Return to shop"
      expect(page).to have_current_path(shop_index_path)
    end
  end


  describe "PATCH #generate_avatar" do
    it "generates a new avatar" do
      allow_any_instance_of(CharacterCreationController).to receive(:generate_avatar_image).and_return("dummy_image_data")
      visit character_creation_index_path
      click_button "Generate Avatar"
      expect(page).to have_content("Avatar successfully generated!")
    end
  end
end
