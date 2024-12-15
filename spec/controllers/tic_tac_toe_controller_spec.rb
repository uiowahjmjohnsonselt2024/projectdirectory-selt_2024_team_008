require 'rails_helper'

RSpec.describe TicTacToeController, type: :controller do
  include Devise::Test::ControllerHelpers

  let!(:user) do
    user = User.create!(username: 'test_user', email: 'test@example.com', password: 'password')
    ShardAccount.create!(user: user, balance: 0) # Initialize with 0 shards
    user
  end

  let(:shard_account) { user.shard_account }
  before do
    sign_in user
    allow(controller).to receive(:current_user).and_return(user)
    allow(user).to receive(:shard_account).and_return(shard_account)
    routes.draw do
      post 'tic_tac_toe/play', to: 'tic_tac_toe#play'
    end
  end
  describe "POST #play" do
    let(:empty_board) { ["", "", "", "", "", "", "", "", ""] }

    context "when the player makes a valid move without ending the game" do
      it "returns a board with the player's move and then CPU moves" do
        post :play, params: { move: 0, current_turn: "X", "board[]" => empty_board }, as: :json
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        # Player placed 'X' at position 0
        # CPU should place 'O' in one of the empty spots
        expect(body["status"]).to eq("continue")
        expect(body["board"][0]).to eq("X")
        expect(body["board"].count("O")).to eq(1)
        expect(body["message"]).to eq("")
        # No shard change on continue
        expect(body["new_shard_balance"]).to eq(0)
      end
    end
    context "when the player makes a winning move" do
      let(:board_almost_won) { ["X","X", "", "", "", "", "", "", ""]}

      it "rewards teh player with 4 shards and returns a winning status" do
        expect(user.shard_account.balance).to eq(0)

        post :play, params: { move: 2, current_turn: "X", "board[]" => board_almost_won }, as: :json
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("win")
        expect(body["board"][2]).to eq("X")
        expect(body["message"]).to include("YOU WIN")
        expect(user.shard_account.reload.balance).to eq(4)
      end
    end
  end

end