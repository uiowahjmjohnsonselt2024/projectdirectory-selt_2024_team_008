class ServerChannel < ApplicationCable::Channel
  def subscribed
    stream_from "server_#{params[:server_id]}"
    ActionCable.server.broadcast(
      "server_#{params[:server_id]}",
      message: "#{current_user.username} has joined the server"
    )
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
    ActionCable.server.broadcast(
      "server_#{params[:server_id]}",
      message: "#{current_user.username} has left the server"
    )

    # Remove user from list of active users in the server
    Server.remove_user(params[:server_id], current_user.id)
  end
end
