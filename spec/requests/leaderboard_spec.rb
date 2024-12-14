require 'rails_helper'

RSpec.describe "Leaderboards", type: :request do
  include ActionView::Helpers::NumberHelper

  let!(:user1) { create(:user, username: "User1_#{SecureRandom.hex(4)}", shard_account: create(:shard_account, balance: 150)) }
  let!(:user2) { create(:user, username: "User2_#{SecureRandom.hex(4)}", shard_account: create(:shard_account, balance: 200)) }
  let!(:user3) { create(:user, username: "User3_#{SecureRandom.hex(4)}", shard_account: create(:shard_account, balance: 100)) }

  before do
    sign_in user1
  end

  describe "GET /leaderboard" do
    it "returns http success" do
      get "/leaderboard"
      expect(response).to have_http_status(:success)
    end

    it "displays the leaderboard with users and their balances" do
      get "/leaderboard"

      expect(response.body).to include("Leaderboard")
      expect(response.body).to include(user1.username)
      expect(response.body).to include(user2.username)
      expect(response.body).to include(user3.username)
      expect(response.body).to include("#{user1.shard_account.balance} Shards")
      expect(response.body).to include("#{user2.shard_account.balance} Shards")
      expect(response.body).to include("#{user3.shard_account.balance} Shards")
    end


    it "limits the leaderboard to the top 10 users" do
      9.times do |i|
        create(:user, username: "User#{SecureRandom.hex(4)}", shard_account: create(:shard_account, balance: 50))
      end

      get "/leaderboard"

      table_body_rows = response.body.scan(/<tbody>.*?<\/tbody>/m).first
      expect(table_body_rows.scan(/<tr>/).count).to be <= 10
    end
  end
end
