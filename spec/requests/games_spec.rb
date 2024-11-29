require 'rails_helper'

RSpec.describe "GamesController", type: :request do
  let(:user) { User.create!(email: "test@example.com", username: "testuser", password: "password") } # Create a test user
  let!(:game) do
    # Create a game with an associated server
    server = Server.create!(name: "Chat Room for Test Game", creator_id: user.id)
    Game.create!(name: "Test Game", creator_id: user.id, server_id: server.id).tap do |game|
      server.update!(game_id: game.id)
    end
  end

  before do
    sign_in user
  end

  describe "GET /games" do
    it "returns a list of games" do
      get games_path
      expect(response).to have_http_status(:ok)
      # Validate the game name is listed
      expect(response.body).to include("Test Game")
      # Validate the game link is correct
      expect(response.body).to include("href=\"/games/#{game.id}\"")
    end
  end

  describe "POST /games" do
    context "with valid parameters" do
      it "creates a new game and its associated server" do
        expect {
          post games_path, params: { game: { name: "New Game" } }
        }.to change(Game, :count).by(1).and change(Server, :count).by(1)

        expect(response).to redirect_to(game_path(Game.last))
        follow_redirect!
        expect(response.body).to include("Game successfully created!")
        expect(Game.last.name).to eq("New Game")
      end
    end

    context "with invalid parameters" do
      it "does not create a new game and shows an error message" do
        expect {
          post games_path, params: { game: { name: "" } }
        }.not_to change(Game, :count)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Error creating game")
      end
    end
  end

  describe "GET /games/:id" do
    context "when the game exists" do
      it "shows the game and its associated server" do
        get game_path(game)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(game.name)
        expect(response.body).to include(game.server.name)
      end
    end

    context "when the game does not exist" do
      it "redirects to root path with an alert" do
        get game_path(id: 999)
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Game not found.")
      end
    end
  end
end