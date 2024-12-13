require 'rails_helper'

RSpec.describe "Inventory Page", type: :request do
  before do
    # Create test items to use in tests
    @mystery_box = Item.create!(item_name: "Mystery Box", item_type: "box")
    @potion = Item.create!(item_name: "Potion of Healing", item_type: "consumable")
  end

  it "User visits inventory page and sees all items" do
    user = User.create!(email: "test@example.com", password: "password", username: "TestUser")

    sign_in user
    get inventory_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Mystery Box")
    expect(response.body).to include("Quantity: 5")
  end

  it "User sees multiple items in their inventory" do
    user = User.create!(email: "multi@example.com", password: "password", username: "MultiUser")
    UserItem.create!(user: user, item: @mystery_box, quantity: 3)
    UserItem.create!(user: user, item: @potion, quantity: 2)

    sign_in user
    get inventory_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Mystery Box")
    expect(response.body).to include("Quantity: 3")
    expect(response.body).to include("Potion of Healing")
    expect(response.body).to include("Quantity: 2")
  end

  it "User sees the 'Return' button" do
    user = User.create!(email: "test@example.com", password: "password", username: "TestUser")

    sign_in user
    get inventory_path

    expect(response.body).to include('Return')
  end
end
