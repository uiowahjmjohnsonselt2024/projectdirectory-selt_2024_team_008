require 'rails_helper'
require 'webmock/rspec'

RSpec.describe ShardAccountsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { User.create!(username: 'test', email: "test@example.com", password: "password") }
  let(:shard_account) { ShardAccount.create!(user: user, balance: 100) }
  let(:valid_session) { { user_id: user.id } }

  before do
    sign_in user
    allow(controller).to receive(:current_user).and_return(user)
    allow(user).to receive(:shard_account).and_return(shard_account)
  end

  describe "POST #convert_currency" do
    context "with valid parameters" do
      before do
        stub_request(:get, /v6.exchangerate-api.com/).to_return(
          body: {
            "conversion_rates" => { "EUR" => 0.85 }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it "returns the converted amount" do
        post :convert_currency, params: { amount: 10, currency: "EUR" }, format: :json
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["converted_amount"]).to eq(6.38) # 10 shards = $7.50, $7.50 * 0.85 = 6.38 EUR
      end
    end

    context "with invalid parameters" do
      it "returns an error when amount is invalid" do
        post :convert_currency, params: { amount: 0, currency: "EUR" }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid input")
      end

      it "returns an error when currency is missing" do
        post :convert_currency, params: { amount: 10, currency: nil }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid input")
      end
    end
  end

  describe "POST #add_funds" do
    context "with valid deposit amount" do
      it "adds funds to the user's shard account" do
        post :add_funds, params: { amount: 50, currency: "USD" }, format: :json
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["success"]).to be_truthy
        expect(shard_account.reload.balance).to eq(150)
      end
    end

    context "with invalid deposit amount" do
      it "returns an error for zero deposit" do
        post :add_funds, params: { amount: 0 }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid deposit amount.")
      end
    end
  end

  # describe "POST #convert" do
  #   context "with valid parameters" do
  #     before do
  #       stub_request(:get, /v6.exchangerate-api.com/).to_return(
  #         body: {
  #           "conversion_rates" => { "EUR" => 0.85 }
  #         }.to_json,
  #         headers: { 'Content-Type' => 'application/json' }
  #       )
  #     end
  #
  #     it "returns the converted amount in the target currency" do
  #       post :convert, params: { shards: 10, currency: "EUR" }, format: :json
  #       expect(response).to have_http_status(:ok)
  #       calculated_value = JSON.parse(response.body)["calculated_value"]
  #       expect(calculated_value).to be_a(Numeric)
  #     end
  #   end
  #
  #   context "with invalid parameters" do
  #     it "returns an error for invalid shard amount" do
  #       post :convert, params: { shards: 0, currency: "EUR" }, format: :json
  #       expect(response).to have_http_status(:unprocessable_entity)
  #       expect(JSON.parse(response.body)["error"]).to eq("Invalid input")
  #     end
  #
  #     it "returns an error for missing currency" do
  #       post :convert, params: { shards: 10, currency: nil }, format: :json
  #       expect(response).to have_http_status(:unprocessable_entity)
  #       expect(JSON.parse(response.body)["error"]).to eq("Invalid input")
  #     end
  #   end
  # end

  describe "POST #buy_item" do
    let(:item) { ShopItem.create!(name: "Sword", price_in_shards: 50) }

    context "with sufficient balance" do
      it "deducts the item cost from the shard account" do
        post :buy_item, params: { item_id: item.id }
        expect(response).to redirect_to(shop_index_path)
        expect(flash[:success]).to eq("You purchased Sword!")
        expect(shard_account.reload.balance).to eq(50)
      end
    end

    context "with insufficient balance" do
      it "does not deduct and shows an error" do
        shard_account.update!(balance: 30)
        post :buy_item, params: { item_id: item.id }
        expect(response).to redirect_to(shop_index_path)
        expect(flash[:error]).to eq("Insufficient Shards.")
        expect(shard_account.reload.balance).to eq(30)
      end
    end
  end

  describe "#valid_card?" do
    it "returns true for valid card details" do
      expect(controller.valid_card?("1234567812345678", "12/25", "123")).to be_truthy
    end

    it "returns false for invalid card details" do
      expect(controller.valid_card?("123", "invalid", "12")).to be_falsey
    end
  end
end
