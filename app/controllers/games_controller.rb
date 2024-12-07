# frozen_string_literal: true

class GamesController < ApplicationController
  def index
    @games = Game.includes(:server).all # Preload associated servers for faster queries
  end

  def create
    ActiveRecord::Base.transaction do
      # Create the server first
      server = Server.create!(
        name: "Chat for #{game_params[:name]}",
        creator_id: current_user.id
      )

      @game = Game.create!(
        name: game_params[:name],
        creator_id: current_user.id,
        server_id: server.id
      )

      server.update!(game_id: @game.id)

      redirect_to game_path(@game), notice: "Game successfully created!"
    end
  rescue ActiveRecord::RecordInvalid => e
    # Rollback and show error message if something goes wrong
    flash[:alert] = "Error creating game: #{e.message}"
    redirect_to root_path
  end

  def show
    @game = Game.find(params[:id])  # Find the game by ID
    @server = @game.server          # Fetch the associated server
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Game not found."
  end

  def ensure_membership
    @game = Game.find_by(id: params[:id])

    unless @game
      return render json: { error: "Game not found" }, status: :not_found
    end

    if @game.memberships.exists?(user: current_user)
      render json: { message: "Membership already exists" }, status: :ok
    else
      membership = @game.memberships.new(user: current_user)

      if membership.save
        render json: { message: "Membership ensured" }, status: :ok
      else
        render json: { error: "Unable to create membership: #{membership.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
      end
    end
  end

  private

  def game_params
    params.require(:game).permit(:name)
  end

end
