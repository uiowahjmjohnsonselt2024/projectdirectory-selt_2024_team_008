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
  end

  describe "POST #play" do
    let(:empty_board) { ["", "", "", "", "", "", "", "", ""] }

    context "when the player makes a valid move without ending the game" do
      it "returns a board with the player's move and then CPU moves" do
        post :play, params: { id: 1, move: 0, current_turn: "X", "board[]" => empty_board }, as: :json
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body["status"]).to eq("continue")
        expect(body["board"][0]).to eq("X")
        expect(body["board"].count("O")).to eq(1)
        expect(body["message"]).to eq("")
        expect(body["new_shard_balance"]).to eq(0)
      end
    end

    context "when the player makes a winning move" do
      let(:board_almost_won) { ["X", "X", "", "", "", "", "", "", ""] }

      it "rewards the player with 4 shards and returns a winning status" do
        expect(user.shard_account.balance).to eq(0)

        post :play, params: { id: 1, move: 2, current_turn: "X", "board[]" => board_almost_won }, as: :json
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body["status"]).to eq("win")
        expect(body["board"][2]).to eq("X")
        expect(body["message"]).to include("YOU WIN")
        expect(user.shard_account.reload.balance).to eq(4)
      end
    end

    context "when the CPU wins" do
      let(:board_almost_lost) { ["X", "O", "X", "X", "O", "", "", "", ""] }

      it "penalizes the player by subtracting 2 shards and returns a loss" do
        expect(user.shard_account.balance).to eq(0)

        allow(controller).to receive(:cpu_turn).and_return({
                                                             board: ["X", "O", "X", "X", "O", "", "", "O", "X"],
                                                             status: "loss",
                                                             message: "YOU LOSE! You Just lost 2 Shards."
                                                           })

        post :play, params: { id: 1, move: 8, current_turn: "X", "board[]" => board_almost_lost }, as: :json
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body["status"]).to eq("loss")
        expect(body["message"]).to eq("YOU LOSE! You Just lost 2 Shards.")
        expect(body["board"]).to eq(["X", "O", "X", "X", "O", "", "", "O", "X"])
        expect(user.shard_account.reload.balance).to eq(-2)
      end
    end

    context "when the game ends in a draw" do
      let(:almost_full_board) { ["X", "O", "X", "X", "O", "O", "O", "X", ""] }

      it "returns a draw status without changing shards" do
        post :play, params: { id: 1, move: 8, current_turn: "X", "board[]" => almost_full_board }, as: :json
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body["status"]).to eq("draw")
        expect(body["message"]).to eq("It was a draw. Please Press 'Go Back' to try again.")
        expect(user.shard_account.reload.balance).to eq(0) # No shard changes
      end
    end

    context "when an unexpected server error occurs" do
      before do
        allow(controller).to receive(:process_game_logic).and_raise(StandardError, "Unexpected error")
      end

      it "returns a 500 error with an error message" do
        post :play, params: { id: 1, move: 0, current_turn: "X", "board[]" => empty_board }, as: :json
        expect(response).to have_http_status(:internal_server_error)
        body = JSON.parse(response.body)

        expect(body["error"]).to include("Unexpected error")
      end
    end
  end
end