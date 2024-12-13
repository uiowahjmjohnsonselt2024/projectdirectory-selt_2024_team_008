class TicTacToeController < ApplicationController
  before_action :authenticate_user!

  respond_to :html, :json

  def index
    @game = Game.find(params[:id])
    @shard_balance = current_user.shard_account.balance
  end

  def play
    move = params[:move].to_i
    # Retrieve the board from 'board[]' parameter
    raw_board = params['board[]'] || []
    Rails.logger.debug "Received raw_board: #{raw_board.inspect}"

    # Convert empty strings back to nil
    board = raw_board.map { |v| v == "" ? nil : v }
    Rails.logger.debug "Processed board: #{board.inspect}"

    current_turn = params[:current_turn]
    Rails.logger.debug "Move: #{move}, Turn: #{current_turn}, Board before move: #{board.inspect}"

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
    Rails.logger.error "Error in TicTacToeController#play: #{e.message}"
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def process_game_logic(move, board, current_turn)
    unless move.between?(0,8) && board[move].nil?
      # If invalid move or spot taken
      return { board: board, status: "continue", message: "" }
    end

    board[move] = current_turn

    if winner?(board, current_turn)
      status = current_turn == "X" ? "win" : "loss"
      message = current_turn == "X" ? "YOU WIN! You Just gained 4 Shards." : "YOU LOSE! You Just lost 2 Shards."
    elsif board_full?(board)
      status = "draw"
      message = "It was a draw. Please Press 'Go Back' to try again."
    else
      status = "continue"
      message = ""
    end
    { board: board, status: status, message: message }
  end

  def cpu_turn(board)
    empty_indices = board.each_index.select { |i| board[i].nil? }
    Rails.logger.debug "CPU turn: empty_indices=#{empty_indices.inspect}"

    cpu_move = empty_indices.sample
    if cpu_move.nil?
      return { board: board, status: "draw", message: "It was a draw. Please Press 'Go Back' to try again." }
    end

    board[cpu_move] = "O"
    if winner?(board, "O")
      { board: board, status: "loss", message: "YOU LOSE! You Just lost 2 Shards." }
    elsif board_full?(board)
      { board: board, status: "draw", message: "It was a draw. Please Press 'Go Back' to try again." }
    else
      { board: board, status: "continue", message: "" }
    end
  end

  def board_full?(board)
    board.all?
  end

  def winner?(board, player)
    winning_positions = [
      [0,1,2], [3,4,5], [6,7,8],
      [0,3,6], [1,4,7], [2,5,8],
      [0,4,8], [2,4,6]
    ]

    winning_positions.any? { |line| line.all? { |i| board[i] == player } }
  end

  def update_shards(status)
    if status == "win"
      current_user.shard_account.increment!(:balance, 4)
    elsif status == "loss"
      current_user.shard_account.decrement!(:balance, 2)
    end
  end
end