class ServersController < ApplicationController

  before_action :ensure_membership, only: :show
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

  private

  def server_params
    params.require(:server).permit(:name)
  end

  def ensure_membership
    @server = Server.find(params[:id])
    return if @server.user_can_access?(current_user)

    # Add the current user to the server's membership if they don't already have access
    @server.memberships.create(user: current_user)
    Rails.logger.info("Added user #{current_user.id} to server #{params[:id]}")
  rescue StandardError => e
    Rails.logger.error("Failed to add user #{current_user.id} to server #{params[:id]}: #{e.message}")
  end

end