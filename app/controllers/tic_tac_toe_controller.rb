class TicTacToeController < ApplicationController
  before_action :authenticate_user!
  before_action :set_game
  before_action :set_server
  before_action :initialize_game_state, only: [:index]
  respond_to :html, :json
  def index

  end


  def set_game
    @game = Game.find_by(id: params[:id])
    unless @game
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Game not found." }
        format.json { render json: { error: "Game not found" }, status: :not_found }
      end
    end
  end
  def set_server
    @server = @game.server
  end
  def initialize_game_state

  end

end