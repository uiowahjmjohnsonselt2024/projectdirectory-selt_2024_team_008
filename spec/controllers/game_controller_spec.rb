require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  include Devise::Test::ControllerHelpers # Include Devise test helpers

  let(:user) { User.create!(email: "test@example.com", username: "testuser", password: "password") } # Create a test user
  let(:user2) { User.create!(email: "test2@example.com", username: "test2user", password: "password") }
  let!(:game) do
    # Create a game with an associated server
    server = Server.create!(name: "Chat Room for Test Game", creator_id: user.id)
    Game.create!(name: "Test Game", creator_id: user.id, server_id: server.id).tap do |game|
      server.update!(game_id: game.id)
    end
  end

  before do
    sign_in user
    sign_in user2
  end

  describe "GET #game_state" do
    context "when the game exists" do
      it "returns the game state as JSON with status :ok" do
        get :game_state, params: { id: game.id, format: :json }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to include("grid", "user_colors", "positions")
      end
    end

    context "when the game does not exist" do
      it "returns a 404 status with an error message" do
        get :game_state, params: { id: 999, format: :json }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response).to eq({ "error" => "Game not found" })
      end
    end
  end

  describe "POST #ensure_membership" do
    context "when the game exists" do
      it "ensures membership and returns a success message" do
        post :ensure_membership, params: { id: game.id, format: :json }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Membership ensured for game and server")
      end

      it "returns a message if the user is already a member" do
        server = game.server

        begin
          Membership.find_or_initialize_by(user: user, game: game, server: server).tap do |membership|
            membership.save! if membership.new_record?
          end
        rescue ActiveRecord::RecordNotUnique
          # Ignore error as membership already exists
          Rails.logger.info "Membership already exists for User #{user.id}, Game #{game.id}, Server #{server.id}"
        end

        post :ensure_membership, params: { id: game.id, format: :json }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Membership ensured for game and server")
      end
    end

    context "when the game does not exist" do
      it "returns a 404 status with an error message" do
        post :ensure_membership, params: { id: 999, format: :json }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response).to eq({ "error" => "Game not found" })
      end
    end
  end
end