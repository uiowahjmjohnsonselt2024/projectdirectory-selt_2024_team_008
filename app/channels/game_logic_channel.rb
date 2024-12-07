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
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams

    game = Game.find_by(id: params[:game_id])
    return unless game && current_user

    # Notify all players that a user has left
    # broadcast_system_message("#{current_user.username} has left the game.", game)
  end

  def make_move(data)
    game = Game.find_by(id: params[:game_id])
    return unless game

    x = data['x'].to_i
    y = data['y'].to_i

    # Validate and process the move
    if valid_move?(game, x, y)
      distance = calculate_distance(game, x, y)

      if distance > 1
        cost = calculate_shard_cost(distance)
        if current_user.shard_account.balance < cost
          transmit(type: 'error', message: "Insufficient shards to move #{distance} tiles.")
          return
        end

        # Deduct shards
        current_user.shard_account.balance -= cost
        current_user.shard_account.save!

        # Broadcast updated shard balance
        GameLogicChannel.broadcast_to(
          game,
          type: 'balance_update',
          user_id: current_user.id,
          balance: current_user.shard_account.balance
        )
      end

      # Clear the user's previous position
      game.grid.each_with_index do |row, row_index|
        row.map! { |cell| cell == current_user.username ? nil : cell }
      end

      # Update game state with username
      game.grid[y][x] = current_user.username
      game.save!

      # Broadcast updated game state
      GameLogicChannel.broadcast_to(
        game,
        type: 'game_state',
        grid: game.grid,
        user_id: current_user.id,
        username: current_user.username,
        x: x, # Target x
        y: y  # Target y
      )
    else
      transmit(type: 'error', message: 'Invalid move')
    end
  end

  private

  def valid_move?(game, target_x, target_y)
    # Ensure the target coordinates are within bounds and the target cell is empty
    target_x.between?(0, game.grid.first.size - 1) &&
      target_y.between?(0, game.grid.size - 1) &&
      game.grid[target_y][target_x].nil?
  end

  def calculate_distance(game, target_x, target_y)
    current_position = find_user_position(game, current_user.username)
    return Float::INFINITY unless current_position

    current_x, current_y = current_position

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