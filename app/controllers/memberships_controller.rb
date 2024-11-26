class MembershipsController < ApplicationController
  before_action :authenticate_user!

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