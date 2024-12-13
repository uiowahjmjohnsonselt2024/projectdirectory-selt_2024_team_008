# frozen_string_literal: true

class GamesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_game, only: [:show, :game_state, :ensure_membership]

  respond_to :html, :json

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

      # Find any existing server-only membership for the user and update it with the game_id
      membership = Membership.find_by(user: current_user, server: server)
      if membership
        membership.update!(game: @game) # Update with the new game
      else
        # Create a new membership if none exists (shouldn't happen often)
        Membership.create!(user: current_user, server: server, game: @game)
      end

      # Assign initial position for the creator
      initial_tile = @game.tiles.find_by(x: 0, y: 0)
      if initial_tile && current_user.username.present?
        initial_tile.update!(
          owner: current_user.username,
          occupant_id: current_user.id,
          color: @game.assign_color(current_user.username)
        )
      else
        Rails.logger.error "Failed to assign initial tile for the creator"
      end

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
    @grid_rows = @game.tiles.order(:y, :x).group_by(&:y).values
    @tiles = @game.tiles.includes(occupant_user: :avatar).map do |tile|
      {
        id: tile.id,
        x: tile.x,
        y: tile.y,
        occupant_avatar: tile.occupant_avatar ? Base64.encode64(tile.occupant_avatar) : nil
      }
    end
  end

  def game_state
    @game.reload

    render json: {
      positions: @game.tiles.map do |tile|
        if tile.occupant_user || tile.owner
          {
            x: tile.x,
            y: tile.y,
            username: tile.occupant_user&.username,
            owner: tile.owner,
            color: tile.color,
            occupant_avatar: tile.occupant_avatar ? tile.occupant_avatar : nil
          }
        end
      end.compact
    }, status: :ok
  end

  def ensure_membership
    @game = Game.find_by(id: params[:id])

    @server = @game.server

    # Ensure membership for both the game and the server
    membership = Membership.find_or_initialize_by(user: current_user, game: @game, server: @server)
    membership.game = @game
    membership.save! if membership.changed?

    @game.assign_color(current_user.username) # Assign a color if not already assigned
    @game.save! # Ensure changes are saved

    if membership.new_record? && membership.save
      render json: { message: "Membership ensured for game and server" }, status: :ok
    elsif membership.persisted?
      render json: { message: "Membership already exists for game and server" }, status: :ok
    else
      render json: { error: "Unable to create membership: #{membership.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
    end
  end

  private

  def set_game
    @game = Game.find_by(id: params[:id])

    unless @game
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Game not found." }
        format.json { render json: { error: "Game not found" }, status: :not_found }
      end
      return
    end
    Rails.logger.debug "Loaded game: #{@game.inspect}"
    Rails.logger.debug "Loaded tiles: #{@game.tiles.inspect}"
  end

  def game_params
    params.require(:game).permit(:name)
  end

end
