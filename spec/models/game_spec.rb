require 'rails_helper'

RSpec.describe Game, type: :model do
  let(:user) { User.create!(email: "test@example.com", username: "testuser", password: "password") }
  let!(:game) do
    server = Server.create!(name: "Chat Room for Test Game", creator_id: user.id)
    Game.create!(name: "Test Game", creator_id: user.id, server_id: server.id).tap do |game|
      server.update!(game_id: game.id)
    end
  end

  describe "#find_user_position" do

    before do
      tile = game.tiles.find_by(x: 3, y: 2) # Find tile at (3, 2)
      tile.update!(occupant: "testuser")
    end

    it "returns the position of the user if present" do
      expect(game.find_user_position("testuser")).to eq([3, 2])
    end

    it "returns nil if the user is not in the grid" do
      expect(game.find_user_position("unknownuser")).to be_nil
    end
  end

  describe "#tile_empty?" do
    before do
      tile = game.tiles.find_by(x: 1, y: 1) # Find tile at (1, 1)
      tile.update!(occupant: "testuser")
    end

    it "returns true if the tile is empty" do
      expect(game.tile_empty?(2, 2)).to be true
    end

    it "returns false if the tile is occupied" do
      expect(game.tile_empty?(1, 1)).to be false
    end
  end

  describe "#initialize_user_colors" do
    let(:user) { User.create!(email: "test@example.com", username: "testuser", password: "password") } # Create a test user

    it "initializes user_colors as an empty hash when a game is created" do
      server = Server.create!(name: "Chat Room for Test Game", creator_id: user.id)
      game = Game.create!(name: "Test Game", creator_id: user.id, server_id: server.id)
      expect(game.user_colors).to eq({})
    end

    it "calls initialize_user_colors before creating the game" do
      server = Server.create!(name: "Chat Room for Test Game", creator_id: user.id)
      game = Game.create!(name: "Test Game", creator_id: user.id, server_id: server.id)
      expect(game.user_colors).to eq({})
    end

    it "does not overwrite existing user_colors" do
      game = Game.new(user_colors: { "testuser" => "tile-color-1" })
      expect(game.user_colors).to eq({ "testuser" => "tile-color-1" })
    end
  end
end