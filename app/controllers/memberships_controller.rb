class MembershipsController < ApplicationController
  before_action :authenticate_user!

  # POST /games/:game_id/memberships
  def create_game_membership
    game = Game.find(params[:game_id])
    membership = game.memberships.new(user: current_user)

    if membership.save
      render json: { message: "You have joined the game." }, status: :ok
    else
      render json: { error: membership.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # DELETE /games/:game_id/memberships/:id
  def destroy_game_membership
    membership = Membership.find_by(user: current_user, game_id: params[:game_id])

    if membership&.destroy
      render json: { message: "You have left the game." }, status: :ok
    else
      render json: { error: "Failed to leave the game." }, status: :unprocessable_entity
    end
  end

  # POST /servers/:server_id/memberships
  def create
    server = Server.find(params[:server_id])
    membership = server.memberships.new(user: current_user)

    if membership.save
      render json: { message: "You have joined the server." }, status: :ok
    else
      render json: { error: membership.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  # DELETE /servers/:server_id/memberships/:id
  def destroy
    membership = Membership.find_by(user: current_user, server_id: params[:server_id])

    if membership&.destroy
      render json: { message: "You have left the server." }, status: :ok
    else
      render json: { error: "Failed to leave the server." }, status: :unprocessable_entity
    end
  end
end