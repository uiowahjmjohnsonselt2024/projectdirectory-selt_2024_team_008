class ServersController < ApplicationController
  def index
    @servers = current_user.joined_servers
  end

  def create
    @server = current_user.created_servers.new(server_params)
    if @server.save
      redirect_to @server
    else
      render :new
    end
  end

  def show
    @server = Server.find(params[:id])
    @messages = @server.messages
  end

  private

  def server_params
    params.require(:server).permit(:name)
  end

end
