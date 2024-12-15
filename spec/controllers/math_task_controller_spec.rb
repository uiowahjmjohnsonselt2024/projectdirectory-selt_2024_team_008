require 'rails_helper'

RSpec.describe MathTaskController, type: :controller do
  include Devise::Test::ControllerHelpers

  let!(:user) do
    user = User.create!(username: 'test_user', email: 'test@example.com', password: 'password')
    ShardAccount.create!(user: user, balance: 10) # Initialize with 10 shards
    user
  end

  let(:shard_account) { user.shard_account }

  before do
    sign_in user
    allow(controller).to receive(:current_user).and_return(user)
    allow(user).to receive(:shard_account).and_return(shard_account)
  end

  describe "POST #chat" do
    context "the user gets a question correct" do
      it "gives two shards to the user" do
        post :chat, params: { math_message: "What is 45 + 55?", solution: 100 }, as: :json
        expect(user.shard_account.balance).to eq(10)
        post :chat, params: { message: 100, solution: 100 }, as: :json
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body["math_message"]).to eq("That's correct! You gained 4 shards.")
        expect(body["new_shard_balance"]).to eq(14)
        expect(user.shard_account.balance).to eq(14)
      end
    end

    context "when the user's answer is incorrect" do
      it "deducts 2 shards from the user" do
        post :chat, params: { math_message: "What is 45 + 55?", solution: 100 }, as: :json
        expect(user.shard_account.balance).to eq(10)
        post :chat, params: { message: 99, solution: 100 }, as: :json
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body["math_message"]).to eq("Sorry. That's the wrong answer. You lose 2 shards.")
        expect(body["new_shard_balance"]).to eq(8)
        expect(user.shard_account.balance).to eq(8)
      end
    end

  end
end
