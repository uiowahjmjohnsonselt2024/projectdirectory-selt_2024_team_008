class GameLogicChannel < ApplicationCable::Channel
  SHARD_COST_PER_TILE = 2

    def subscribed
    game = Game.find_by(id: params[:game_id])

    if game && current_user
      stop_all_streams
      stream_for game

      # Ensure a unique membership record for the user
      begin
        Membership.find_or_initialize_by(user: current_user, game: game, server: game.server)
        # Rails.logger.debug "Membership created or found: #{membership.inspect}"
      rescue ActiveRecord::RecordNotUnique
        Rails.logger.info("Membership already exists for user #{current_user.id} in game #{game.id}")
      end

      # Assign a color to the user if they don't already have one
      game.assign_color(current_user.username)
      game.save!

      unless game.tiles.exists?(occupant: current_user.username)
        # Find the farthest tile for the new player
        farthest_tile = game.find_farthest_tile
        if farthest_tile
          farthest_tile.update!(
            occupant: current_user.username,
            owner: current_user.username,
            color: game.assign_color(current_user.username)
          )
        else
          Rails.logger.error "Failed to find a suitable tile for new player"
        end
      end

      # Send the current game state to the new subscriber
      transmit_game_state(game)
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
    current_position = game.find_user_position(current_user.username)
    distance = calculate_distance(game, x, y)

    if distance.nil?
      # Trigger an "enter tile" action
      trigger_tile_action(game, x, y)
      return
    end

    # Validate the move before proceeding
    unless valid_move?(game, x, y)
      return # Exit early if the move is invalid
    end

    target_tile = game.tiles.find_by(x: x, y: y)
    return unless target_tile

    # Restrict movement to owned tiles
    if target_tile.owner.present? && target_tile.owner != current_user.username
      transmit({ type: 'move_error', message: 'You can only move into tiles you own.' })
      return
    end

    ActiveRecord::Base.transaction do

      # Calculate distance and shard cost
      distance = calculate_distance(game, x, y)
      cost = calculate_shard_cost(distance)

      Rails.logger.debug("Current position for #{current_user.username}: x: #{x}, y: #{y}")
      Rails.logger.debug("Distance: #{distance}, Cost: #{cost}")

      # Check shard balance if move costs shards
      if distance > 0 && current_user.shard_account.balance < cost
        transmit({ type: 'balance_error', message: "Insufficient shards to move #{distance} tiles." })
        return
      end

      # Deduct shards for multi-tile moves
      if distance > 0
        current_user.shard_account.update!(balance: current_user.shard_account.balance - cost)

        # Broadcast balance update
        GameLogicChannel.broadcast_to(
          game,
          type: 'balance_update',
          user_id: current_user.id,
          balance: current_user.shard_account.balance
        )
      end

      # Prepare updates for the frontend
      updates = []

      # Clear previous position
      if current_position
        old_x, old_y = current_position
        old_tile = game.tiles.find_by(x: old_x, y: old_y)
        old_tile.update!(occupant: nil) if old_tile
        updates << { x: old_x, y: old_y, username: nil, color: old_tile&.color, owner: old_tile&.owner }
      end

      # Update target tile with new position
      target_tile.update!(
        occupant: current_user.username,
        owner: target_tile.owner || current_user.username,
        color: game.user_colors[current_user.username]
      )
      updates << { x: x, y: y, username: current_user.username, color: target_tile.color }

      # Broadcast updates together
      GameLogicChannel.broadcast_to(
        game,
        type: 'tile_updates',
        updates: updates
      )
    end
  end

  private

  def valid_move?(game, target_x, target_y)
    current_position = game.find_user_position(current_user.username)
    return false unless current_position

    current_x, current_y = current_position

    # Check for valid tile bounds
    return false unless target_x.between?(0, 9) && target_y.between?(0, 9)

    # Check for horizontal or vertical move
    valid_horizontal_or_vertical = (target_x == current_x || target_y == current_y)
    return false unless valid_horizontal_or_vertical

    # Check ownership and occupancy
    tile = game.tiles.find_by(x: target_x, y: target_y)
    tile.present? && tile.occupant.nil? && (tile.owner.nil? || tile.owner == current_user.username)
  end

  def calculate_distance(game, target_x, target_y)
    current_position = game.find_user_position(current_user.username)
    return Float::INFINITY unless current_position

    current_x, current_y = current_position

    return nil if current_x == target_x && current_y == target_y

    unless valid_move?(game, target_x, target_y)
      raise ArgumentError, "Target coordinates (#{target_x}, #{target_y}) are out of bounds."
    end

    # Calculate Chebyshev distance
    [ (target_x - current_x).abs, (target_y - current_y).abs ].max
  end

  def calculate_shard_cost(distance)
    # CAN BE CHANGED
    if distance == nil
      0
    else
      SHARD_COST_PER_TILE * [1, distance.to_i].max
    end
  end

  def transmit_game_state(game)
    positions = game.tiles.map do |tile|
      next unless tile.occupant || tile.owner

        {
          x: tile.x,
          y: tile.y,
          username: tile.occupant,
          color: tile.color,
          owner: tile.owner
        }
    end.compact

    GameLogicChannel.broadcast_to(
      game,
      type: 'game_state',
      positions: positions
    )
  end

  def trigger_tile_action(game, x, y)
    # Add logic for what happens when a player enters their current tile
    GameLogicChannel.broadcast_to(
      game,
      type: 'tile_action',
      x: x,
      y: y,
      message: "Player has entered the tile at (#{x}, #{y})."
    )
  end

  def broadcast_system_message(message, game)
    GameLogicChannel.broadcast_to(game, { type: 'system', message: message })
  end
end