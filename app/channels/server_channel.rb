class ServerChannel < ApplicationCable::Channel
  def subscribed
    server = Server.find_by(id: params[:server_id])

    if server && current_user && server.user_can_access?(current_user)
      Rails.logger.info("Subscribed to server_#{params[:server_id]}")
      stream_from "server_#{params[:server_id]}"
      ActionCable.server.broadcast(
        "server_#{params[:server_id]}",
        { message: "#{current_user.username} has joined the server" }
      )
    else
      Rails.logger.info("Subscription rejected for server_#{params[:server_id]}")
      reject
      end
    end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
    ActionCable.server.broadcast(
      "server_#{params[:server_id]}",
      { message: "#{current_user.username} has joined the server" }
    )

    # Remove user from list of active users in the server
    server = Server.find_by(id: params[:server_id])
    server&.remove_user(current_user)
  end
end
