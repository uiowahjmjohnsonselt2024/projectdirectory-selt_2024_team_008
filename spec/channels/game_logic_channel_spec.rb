require 'rails_helper'

RSpec.describe GameLogicChannel, type: :channel do
  let(:user) { User.create!(email: "test@example.com", username: "testuser", password: "password") }
  let!(:game) do
    # Create a game with an associated server
    server = Server.create!(name: "Chat Room for Test Game", creator_id: user.id)
    Game.create!(name: "Test Game", creator_id: user.id, server_id: server.id).tap do |game|
      server.update!(game_id: game.id)
    end
  end

  before do
    server = game.server
    Membership.where(user: user, server: server, game: game).destroy_all
    game.reload
    stub_connection current_user: user
  end

  describe "#subscribed" do
    context "when the game is not found" do
      it "rejects the subscription" do
        subscribe(game_id: -1) # Nonexistent game ID
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
    let(:data) { { 'x' => 0, 'y' => 1, color: 'tile-color-1' } }
    let(:initial_balance) {20}
    let(:shard_account) { double("ShardAccount", balance: initial_balance) }

    before do
      subscribe(game_id: game.id)
      game.update_grid(0, 0, user.username) # Place user at initial position
      game.assign_color(user.username)     # Assign a color to the user
      game.save!
      allow(user).to receive(:shard_account).and_return(shard_account)
    end

    context "when the move is valid" do
      it "updates the grid and broadcasts the changes" do
        allow(GameLogicChannel).to receive(:broadcast_to).and_call_original

        expect {
          perform :make_move, data
        }.to have_broadcasted_to(game).with(
          type: 'tile_updates',
          updates: [
            { x: 0, y: 0, username: nil, color: nil },
            { x: 0, y: 1, username: user.username, color: 'tile-color-1' }
          ]
        )

        # puts GameLogicChannel.broadcast_to(game, anything).inspect
      end
    end

    context "when the move is invalid" do
      it "does not broadcast any updates" do
        data['x'] = 10 # Out of bounds
        expect {
          perform :make_move, data
        }.not_to have_broadcasted_to(game)
      end
    end

    context "when the user does not have enough shards for the move" do
      let(:initial_balance) { 1 } # Insufficient balance
      let(:distance) { 2 }        # Multi-tile move
      let(:cost) { (distance - 1) * GameLogicChannel::SHARD_COST_PER_TILE }

      it "transmits a balance error message and does not update the grid" do
        game.update_grid(0, 0, user.username)
        game.assign_color(user.username)
        game.save!

        subscribe(game_id: game.id)

        perform :make_move, { 'x' => 0, 'y' => 1 }
        game.reload
        # puts game.grid.inspect

        expect(subscription).to receive(:transmit).with(
          { type: 'balance_error', message: "Insufficient shards to move 2 tiles." }
        )
        perform :make_move, { 'x' => 0, 'y' => 3 }
        game.reload
        # puts "Grid after invalid move: #{game.grid.inspect}"

        expect(game.grid[0][0]).to be_nil         # Previous position cleared
        expect(game.grid[1][0]).to eq(user.username) # Valid move executed
        expect(game.grid[3][0]).to be_nil
      end
    end

    context "when the user has enough shards for the move" do
      let(:initial_balance) { 10 } # Sufficient balance
      let(:distance) { 2 }         # Multi-tile move
      let(:cost) { (distance - 1) * GameLogicChannel::SHARD_COST_PER_TILE }

      before do
        # Mock the shard account with sufficient balance
        shard_account = double("ShardAccount", balance: initial_balance)
        allow(user).to receive(:shard_account).and_return(shard_account)
        allow(shard_account).to receive(:update!).with(hash_including(:balance)) do |args|
          shard_account.instance_variable_set(:@balance, args[:balance])
        end

          # Set up initial grid state
          game.update_grid(0, 0, user.username)
          game.assign_color(user.username)
          game.save!
          puts game.grid.inspect

          subscribe(game_id: game.id)
        end

      it "deducts shards and updates the grid" do
        perform :make_move, { 'x' => 0, 'y' => 2 }
        game.reload
        puts game.grid.inspect

        expect(game.grid[0][0]).to be_nil         # Previous position cleared
        expect(game.grid[2][0]).to eq(user.username)

        expect(user.shard_account).to have_received(:update!).with(balance: initial_balance - cost)
      end
    end
  end

  describe "#valid_move?" do
    before { game.update_grid(0, 0, user.username) }

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
      # Temporarily make the private method public for testing
      GameLogicChannel.class_eval { public :calculate_distance }

      game.update_grid(0, 0, user.username) # Place user at initial position
      game.save!

      subscribe(game_id: game.id)
    end

    after do
      # Revert the method back to private after the test
      GameLogicChannel.class_eval { private :calculate_distance }
    end

    it "raises an ArgumentError when the target coordinates are out of bounds" do
      target_x, target_y = 6, 6 # Invalid coordinates (out of 6x6 grid bounds)

      expect {
        subscription.send(:calculate_distance, game, target_x, target_y)
      }.to raise_error(ArgumentError, "Target coordinates (6, 6) are out of bounds.")
    end

    it "does not raise an error for valid coordinates" do
      target_x, target_y = 0, 1 # Valid move

      expect {
        subscription.send(:calculate_distance, game, target_x, target_y)
      }.not_to raise_error
    end

    it "calculates the correct distance for valid coordinates" do
      target_x, target_y = 2, 0 # Valid move (Chebyshev distance = 2)

      distance = subscription.send(:calculate_distance, game, target_x, target_y)
      expect(distance).to eq(2)
    end
  end
end
