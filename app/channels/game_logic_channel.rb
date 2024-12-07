class GameLogicChannel < ApplicationCable::Channel
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
        x: x,
        y: y
      )
    else
      transmit(error: "Invalid move")
    end
  end

  private

  def valid_move?(game, x, y)
    x.between?(0, 5) && y.between?(0, 5) && game.grid[y][x].nil?
  end

  def transmit_game_state(game)
    transmit({ type: 'game_state', grid: game.grid })
  end

  def broadcast_system_message(message, game)
    GameLogicChannel.broadcast_to(game, { type: 'system', message: message })
  end
end