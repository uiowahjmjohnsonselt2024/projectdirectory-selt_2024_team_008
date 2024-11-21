class ServersController < ApplicationController

  before_action :ensure_membership, only: :show
  skip_before_action :verify_authenticity_token, only: [:update_status]
  def index
    @servers = current_user.joined_servers
    respond_to do |format|
      format.html { render plain: "Servers list: #{@servers.map(&:name).join(', ')}" }
    end
  end

  def create
    @server = current_user.created_servers.new(server_params)
    if @server.save
      redirect_to @server
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @server = Server.includes(:memberships, :messages).find(params[:id])
    @messages = @server.messages
  end

  def ensure_membership
    @server = Server.find(params[:id])

    # Check if the current user already has access
    if @server.user_can_access?(current_user)
      Rails.logger.info("User #{current_user.id} already has access to server #{params[:id]}")
      return
    end

    # Add the current user to the server's membership if they don't already have access
    @server.memberships.create!(user: current_user)
    Rails.logger.info("Added user #{current_user.id} to server #{params[:id]}")
  rescue StandardError => e
    Rails.logger.error("Failed to add user #{current_user.id} to server #{params[:id]}: #{e.message}")
  end

  def update_status
    server = Server.find_by(id: params[:id])
    return render json: { error: 'Server not found' }, status: :not_found unless server

    if current_user
      # Broadcast the status update to all users in the server
      ActionCable.server.broadcast(
        "server_#{server.id}_users",
        {
          user_id: current_user.id,
          status: params[:status]
        }
      )

      # Update user's `last_seen_at` for tracking status
      if params[:status] == 'online'
        current_user.update!(last_seen_at: Time.current)
      else
        current_user.update!(last_seen_at: nil)
      end

      render json: { message: "Status updated to #{params[:status]}" }, status: :ok
    else
      render json: { error: 'User not authenticated' }, status: :unauthorized
    end
  end

  private

  def server_params
    params.require(:server).permit(:name)
  end

end