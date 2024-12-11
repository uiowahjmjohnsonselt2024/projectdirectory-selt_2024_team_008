class TicTacToeController < ApplicationController
  before_action :authenticate_user!

  respond_to :html, :json
  def index
    @shard_balance = current_user.shard_account.balance
  end

  def process_game_logic(move, board, currentTurn)

  end

  #Checks if the board is filled. If so game will turn out to be a Scratch (as long as nobody won on the last move)
  def board_full?(board)
    board.all?
  end

  def winner?(board, player)

    # List of all winning positions for either the user or the CPU
    winning_posiitons = [
      [0,1,2], [3,4,5], [6,7,8],
      [0,3,6], [1,4,7], [2,5,8],
      [0,4,8], [2,4,6]
    ]


    # Checks each winning position with the input of the user and CPU after every move.
    winning_posiitons.each do |player_input|
      return true if player_input.all? { |i| board[i] == player}
    end
    false
  end

end