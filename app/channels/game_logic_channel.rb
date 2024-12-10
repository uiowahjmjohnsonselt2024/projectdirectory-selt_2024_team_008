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

      # Use the same logic as ensure_membership to assign the starting position
      unless game.grid.flatten.any? { |tile| tile[:occupant] == current_user.username }
        x, y = game.assign_starting_position(current_user.username) # Capture the assigned position
        game.purchase_tile(x, y, current_user.username) # Assign ownership to the newly assigned tile
        game.update_grid(x, y, current_user.username)
        game.reload
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
    current_position = find_user_position(game, current_user.username)

    # Validate the move before proceeding
    unless valid_move?(game, x, y)
      Rails.logger.debug("Not valid move returning")
      return # Exit early if the move is invalid
    end

    ActiveRecord::Base.transaction do

      # Calculate distance and shard cost
      distance = calculate_distance(game, x, y)
      cost = calculate_shard_cost(distance)

      Rails.logger.debug("Current position for #{current_user.username}: x: #{x}, y: #{y}")
      Rails.logger.debug("Distance: #{distance}, Cost: #{cost}")

      total_cost = cost
      target_tile = game.grid[y][x]

      # Check if tile needs to be purchased
      if target_tile[:owner].nil? && target_tile[:occupant].nil? && target_tile[:owner] != current_user.username
        total_cost += SHARD_COST_PER_TILE # Add purchase cost for the tile
      end

      # Check if the move itself incurs a shard cost
      distance = calculate_distance(game, x, y)
      if distance > 1
        total_cost += calculate_shard_cost(distance) # Add the movement cost
      end

      # Check shard balance for the total cost
      if total_cost > 0 && current_user.shard_account.balance < total_cost
        transmit({ type: 'balance_error', message: 'Insufficient shards to make this move and/or purchase the tile.' })
        return
      end

      Rails.logger.debug "Total cost #{total_cost}"

      # Deduct shards for multi-tile moves
      if total_cost > 0
        current_user.shard_account.update!(balance: current_user.shard_account.balance - cost)

        # Broadcast balance update
        GameLogicChannel.broadcast_to(
          game,
          type: 'balance_update',
          user_id: current_user.id,
          balance: current_user.shard_account.balance
        )
      end

      # Handle tile ownership if it needs to be purchased
      if target_tile[:owner] != current_user.username
        game.purchase_tile(x, y, current_user.username)
      end

      # Prepare updates for the frontend
      updates = []

      # Clear previous position
      if current_position
        old_x, old_y = current_position
        Rails.logger.debug("Clearing occupant at (#{old_x}, #{old_y})")
        previous_tile = game.grid[old_y][old_x]
        previous_tile[:occupant] = nil
        updates << { x: old_x, y: old_y, owner: previous_tile[:owner], occupant: nil, color: previous_tile[:color] }
      end

      # Update grid with new position
      game.update_grid(x, y, current_user.username)
      target_tile = game.grid[y][x]
      updates << { x: x, y: y, owner: target_tile[:owner], occupant: target_tile[:occupant], color: target_tile[:color] }

      Rails.logger.debug("Updates to broadcast: #{updates}")

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
    current_position = find_user_position(game, current_user.username)

    # Validate current position exists
    unless current_position.is_a?(Array) && current_position.size == 2
      Rails.logger.error("Invalid current position: #{current_position.inspect}")
      return false
    end

    current_x, current_y = current_position

    # Validate grid structure
    current_tile = game.grid.dig(current_y, current_x)
    target_tile = game.grid.dig(target_y, target_x)

    unless current_tile && target_tile
      Rails.logger.error("Invalid tiles: current_tile=#{current_tile.inspect}, target_tile=#{target_tile.inspect}")
      return false
    end

    # Log debug info for clarity
    Rails.logger.debug("Current tile: #{current_tile}, Target tile: #{target_tile}")

    # Check if move is valid
    adjacent = (target_x - current_x).abs <= 1 && (target_y - current_y).abs <= 1
    if adjacent && target_tile[:owner].nil? && target_tile[:occupant].nil?
      return true
    end

    Rails.logger.debug("Move is not valid")
    false
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
    Rails.logger.debug "Searching for user '#{username}' in grid..."
    game.grid.each_with_index do |row, y|
      Rails.logger.debug "Searching row #{y}: #{row}"
      x = row.index do |tile|
        occupant = tile[:occupant] || tile["occupant"] # Handle both symbol and string keys
        Rails.logger.debug "Checking tile #{tile} for occupant match with '#{username}'"
        occupant.to_s.strip == username.to_s.strip # Ensure both are strings and trimmed
      end
      return [x, y] if x # Return immediately when a match is found
    end
    Rails.logger.debug "Occupant '#{username}' not found in grid"
    nil # Return nil if no position is found
  end

  def transmit_game_state(game)
    positions = game.grid.each_with_index.flat_map do |row, y|
      row.map.with_index do |tile, x|
        {
          x: x,
          y: y,
          owner: tile[:owner]&.username || tile[:owner],
          occupant: tile[:occupant]&.username || tile[:occupant],
          color: tile[:color]
        }
      end
    end

    GameLogicChannel.broadcast_to(game, { type: 'game_state', positions: positions })
  end

  def broadcast_system_message(message, game)
    GameLogicChannel.broadcast_to(game, { type: 'system', message: message })
  end
end