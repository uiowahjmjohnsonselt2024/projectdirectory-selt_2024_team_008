require 'rails_helper'

RSpec.describe GameLogicChannel, type: :channel do
  let(:user) { User.create!(email: "test@example.com", username: "testuser", password: "password") }
  let!(:game) do
    server = Server.create!(name: "Chat Room for Test Game", creator_id: user.id)
    Game.create!(name: "Test Game", creator_id: user.id, server_id: server.id).tap do |game|
      server.update!(game_id: game.id)
    end
  end

  before do
    Membership.where(user: user, server: game.server, game: game).destroy_all
    stub_connection current_user: user
  end

  describe "#subscribed" do
    context "when the game is not found" do
      it "rejects the subscription" do
        subscribe(game_id: -1)
        expect(subscription).to be_rejected
      end
    end
  end

  describe "#unsubscribed" do
    it "stops all streams" do
      subscribe(game_id: game.id)
      unsubscribe
      expect(subscription.streams).to be_empty
    end
  end

  describe "#make_move" do
    let(:data) { { 'x' => 0, 'y' => 1, 'color' => 'tile-color-1' } }
    let(:initial_balance) { 20 }
    let(:shard_account) { double("ShardAccount") }
    let(:tile) { game.tiles.find_by(x: 0, y: 1) }

    before do
      shard_account.instance_variable_set(:@balance, initial_balance)

      allow(user).to receive(:shard_account).and_return(shard_account)

      allow(shard_account).to receive(:update!).with(hash_including(:balance)) do |args|
        shard_account.instance_variable_set(:@balance, args[:balance])
      end

      allow(shard_account).to receive(:balance) do
        shard_account.instance_variable_get(:@balance)
      end

      subscribe(game_id: game.id)
      game.tiles.find_by(x: 0, y: 1).update!(occupant_id: nil)
      game.assign_color(user.username)
      game.save!
    end

    context "when the move is valid" do
      it "updates the tile and broadcasts the changes" do
        allow(GameLogicChannel).to receive(:broadcast_to).and_call_original
        tile.update!(occupant_id: nil)

        expect {
          perform :make_move, data
        }.to change { tile.reload.occupant_id }.from(nil).to(user.id)

        expected_payload = {
          type: "game_state",
          positions: [
            {
              x: 0,
              y: 1,
              username: user.username,
              color: "tile-color-1",
              owner: nil,
              occupant_avatar: nil
            }
          ]
        }

        expect { GameLogicChannel.broadcast_to(game, expected_payload) }
      end
    end

    context "when the move is invalid" do
      it "does not broadcast any updates" do
        data['x'] = 10
        target_x = 10
        target_y = 1

        expect {
          perform :make_move, data
        }.to raise_error(ArgumentError, "Target coordinates (#{target_x}, #{target_y}) are out of bounds.")
      end
    end

    context "when the user does not have enough shards for the move" do
      let(:initial_balance) { 1 }
      let(:distance) { 2 }
      let(:cost) { (distance - 1) * GameLogicChannel::SHARD_COST_PER_TILE }

      it "transmits a balance error message and does not update the grid" do
        expect(subscription).to receive(:transmit).with(
          hash_including(
            type: 'balance_error',
            message: "Insufficient shards to move #{distance} tiles."
          )
        )

        perform :make_move, { 'x' => 0, 'y' => 2 }
      end
    end

    context "when the user has enough shards for the move" do
      let(:initial_balance) { 10 }
      let(:distance) { 2 }
      let(:cost) { distance * GameLogicChannel::SHARD_COST_PER_TILE }

      it "deducts shards and updates the tile" do
        perform :make_move, { 'x' => 0, 'y' => 2 }
        tile = game.tiles.find_by(x: 0, y: 2)
        expect(tile.occupant_id).to eq(user.id)
        expect(shard_account).to have_received(:update!).with(balance: initial_balance - cost)
      end
    end
  end

  describe "#valid_move?" do
    before { game.tiles.find_by(x: 0, y: 0).update!(occupant_id: user.id) }

    it "returns true for a valid move" do
      subscribe(game_id: game.id)
      channel = subscription

      expect(channel.send(:valid_move?, game, 0, 1)).to be true
    end

    it "returns false for an invalid move" do
      subscribe(game_id: game.id)
      channel = subscription

      expect(channel.send(:valid_move?, game, 10, 10)).to be false
    end
  end

  describe "#calculate_distance" do
    before do
      GameLogicChannel.class_eval { public :calculate_distance }
      game.tiles.find_by(x: 0, y: 0).update!(occupant_id: user.id)
    end

    after do
      GameLogicChannel.class_eval { private :calculate_distance }
    end

    it "raises an ArgumentError when the target coordinates are out of bounds" do
      subscribe(game_id: game.id)

      expect {
        subscription.send(:calculate_distance, game, 10, 10)
      }.to raise_error(ArgumentError, "Target coordinates (10, 10) are out of bounds.")
    end

    it "calculates the correct distance for valid coordinates" do
      subscribe(game_id: game.id)
      distance = subscription.send(:calculate_distance, game, 2, 0)
      expect(distance).to eq(2)
    end
  end
end