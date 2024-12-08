class GameLogicChannel < ApplicationCable::Channel
  SHARD_COST_PER_TILE = 2

    def subscribed
    game = Game.find_by(id: params[:game_id])

    if game && current_user
      stop_all_streams
      stream_for game

      # Notify all players that a user has joined
      # broadcast_system_message("#{current_user.username} has joined the game.", game)

      # Send the current game state to the new subscriber
      # transmit_game_state(game)
      # Send the current game state to the new subscriber
      GameLogicChannel.broadcast_to(
        game,
        type: 'game_state',
        grid: game.grid
      )
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams

    game = Game.find_by(id: params[:game_id])
    nil unless game && current_user

    # Notify all players that a user has left
    # broadcast_system_message("#{current_user.username} has left the game.", game)
  end

  def make_move(data)
    game = Game.find_by(id: params[:game_id])
    return unless game

    x = data['x'].to_i
    y = data['y'].to_i
    current_position = find_user_position(game, current_user.username)

    ActiveRecord::Base.transaction do
      if valid_move?(game, x, y)
        # Calculate distance and shard cost
        distance = calculate_distance(game, x, y)
        cost = calculate_shard_cost(distance)

        # Check shard balance if move costs shards
        if distance > 1 && current_user.shard_account.balance < cost
          transmit({ type: 'balance_error', message: "Insufficient shards to move #{distance} tiles." })
          return
        end

        # Deduct shards for multi-tile moves
        if distance > 1
          current_user.shard_account.update!(balance: current_user.shard_account.balance - cost)
        end

        # Prepare updates for the frontend
        updates = []

        # Clear previous position
        if current_position
          old_x, old_y = current_position
          game.grid[old_y][old_x] = nil
          updates << { x: old_x, y: old_y, username: nil }
        end

        # Update grid with new position
        game.update_grid(x, y, current_user.username)
        updates << { x: x, y: y, username: current_user.username }

        # Broadcast updates together
        GameLogicChannel.broadcast_to(
          game,
          type: 'tile_updates',
          updates: updates
        )
      else
        transmit({ type: 'error', message: 'Invalid move' })
      end

      Rails.logger.debug("Current position for #{current_user.username}: x: #{x}, y: #{y}")
      Rails.logger.debug("Distance: #{distance}, Cost: #{cost}")
    end
  end

  private

  def valid_move?(game, target_x, target_y)
    current_position = find_user_position(game, current_user.username)
    return false unless current_position

    current_x, current_y = current_position

    # Check for valid tile bounds
    return false unless target_x.between?(0, 5) && target_y.between?(0, 5)

    # Check for horizontal or vertical move
    valid_horizontal_or_vertical = (target_x == current_x || target_y == current_y)
    return false unless valid_horizontal_or_vertical

    # Check if the target tile is empty
    game.grid[target_y][target_x].nil?
  end

  def calculate_distance(game, target_x, target_y)
    current_position = find_user_position(game, current_user.username)
    return Float::INFINITY unless current_position

    current_x, current_y = current_position

    return 0 if current_x == target_x && current_y == target_y

    unless valid_move?(game, target_x, target_y)
      raise ArgumentError, "Target coordinates (#{target_x}, #{target_y}) are out of bounds."
    end

    # Calculate Chebyshev distance
    [ (target_x - current_x).abs, (target_y - current_y).abs ].max
  end

  def calculate_shard_cost(distance)
    # CAN BE CHANGED: 2 shards per tile beyond the first
    (distance - 1) * SHARD_COST_PER_TILE
  end

  def find_user_position(game, username)
    position = game.grid.flatten.index(username)
    return nil unless position

    [position % game.grid.first.size, position / game.grid.first.size]
  end

  def transmit_game_state(game)
    transmit({ type: 'game_state', grid: game.grid })
  end

  def broadcast_system_message(message, game)
    GameLogicChannel.broadcast_to(game, { type: 'system', message: message })
  end
end