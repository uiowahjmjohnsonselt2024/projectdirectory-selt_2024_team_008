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

      # Automatically add the creator as a member of both the game and the server
      membership = Membership.find_or_initialize_by(user: current_user, server: server)
      membership.game = @game # Update the game association if needed
      membership.save! if membership.new_record? || membership.changed?

      # Set the creator's initial position on the grid
      initial_x, initial_y = 0, 0
      @game.update_grid(initial_x, initial_y, current_user.username)

      # Assign a color to the creator
      @game.assign_color(current_user.username)
      @game.save!

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
  end

  def game_state
    position = @game.find_user_position(current_user.username)
    Rails.logger.debug "Game state grid: #{@game.grid.inspect}"
    Rails.logger.debug "User position: #{position.inspect}"

    render json: {
      grid: @game.grid,
      user_colors: @game.user_colors, # Include user colors
      positions: @game.grid.each_with_index.flat_map do |row, y|
        row.map.with_index do |username, x|
          { x: x, y: y, username: username, color: @game.user_colors[username] } if username
        end
      end.compact
    }, status: :ok
  end

  def ensure_membership
    @game = Game.find_by(id: params[:id])

    @server = @game.server

    # Ensure membership for both the game and the server
    membership = Membership.find_or_initialize_by(user: current_user, game: @game, server: @server)

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
    end
  end

  def game_params
    params.require(:game).permit(:name)
  end

end
