class TicTacToeController < ApplicationController
  before_action :authenticate_user!

  respond_to :html, :json
  def index
    @shard_balance = current_user.shard_account.balance
  end

  def play
    move = params[:move].to_i
    board = params[:board]
    current_turn = params[:current_turn]
    board = board.map{ |v| v == "" ? nil : v } # Maps each of the empty spaces with nil or leaves the number how it was originally

    result = process_game_logic(move, board, current_turn)

    if result[:status] != "continue"
      update_shards(result[:status])
    else
      cpu_move_result = cpu_turn(result[:board])
      if cpu_move_result[:status] != "continue"
        update_shards(cpu_move_result[:status])
      end
      result = cpu_move_result || result
    end
    render json: {
      board: result[:board],
      status: result[:status],
      message: result[:message],
      new_shard_balance: current_user.shard_account.balance
    }
    rescue StandardError => e
      render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

# In this function, if there is a winner, then display you won. If loser, then display you lose.
# If the board is full, then the status would be that there is a draw.
  def process_game_logic(move, board, current_turn)

    board[move] = current_turn
    if winner?(board, current_turn)
      status = current_turn == "X" ? "win" : "loss"
      message = current_turn == "X" ? "YOU WIN! You Just gained 50 Shards." : "YOU LOSE! You Just lost 25 Shards."
    elsif board_full?(board)
      status = "draw"
      message = "It was a draw. Please Press 'Go Back' to try again."
    else
      status = "continue"
      message = ""
    end
    { board: board, status: status, message: message } # Updates the hash
  end

  # Handles the CPU's turn.
  def cpu_turn(board)
    empty_indices = board.each_index.select {|i| board[i].nil?}
    cpu_move = empty_indices.sample # Allows for a random spot to be chosen

    # Since the CPU always will attempt to go last every time, the cpu move will still be nil if nothing happened.
    if cpu_move.nil?
      return {board: board, status: "draw", message: "It was a draw. Please Press 'Go Back' to try again."}
    end
    board[cpu_move] = "O"
    if winner?(board, "O")
      {board: board, status: "loss", message: "YOU LOSE! You Just lost 25 Shards."}
    elsif board_full?(board)
      {board:board, status: "draw", message: "It was a draw. Please Press 'Go Back' to try again."}
    else
      {board: board, status: "continue", message: ""}
    end
  end

  #Checks if the board is filled. If so game will turn out to be a Scratch (as long as nobody won on the last move)
  def board_full?(board)
    board.all?
  end

  # Determines if the player or the CPU won the game
  def winner?(board, player)
    # List of all winning positions for either the user or the CPU
    winning_positions = [
      [0,1,2], [3,4,5], [6,7,8],
      [0,3,6], [1,4,7], [2,5,8],
      [0,4,8], [2,4,6]
    ]


    # Checks each winning position with the input of the user and CPU after every move.
    winning_positions.each do |player_input|
      return true if player_input.all? { |i| board[i] == player}
    end
    false
  end
  # Updates the user's shard count depending on a win or a loss
  def update_shards(status)
    if status == "win"
      current_user.shard_account.increment!(:balance, 50)
    elsif status == "loss"
      current_user.shard_account.decrement!(:balance, 25)
    end
  end

end