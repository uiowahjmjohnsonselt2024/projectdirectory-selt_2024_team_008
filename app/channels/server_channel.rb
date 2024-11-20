class ServerChannel < ApplicationCable::Channel
  def subscribed
    server = Server.find_by(id: params[:server_id])

    if server && current_user
      server.memberships.find_or_create_by!(user: current_user)
      Rails.logger.info("Ensured user #{current_user.id} has membership to server #{server.id}")

      if server.user_can_access?(current_user)
        Rails.logger.info("Subscribed to server_#{params[:server_id]}")
        stream_from "server_#{params[:server_id]}"
        ActionCable.server.broadcast(
          "server_#{params[:server_id]}",
          { message: "#{current_user.username} has joined the chat room" }
        )
      else
        Rails.logger.info("Subscription rejected for server_#{params[:server_id]}")
        reject
        end
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
    ActionCable.server.broadcast(
      "server_#{params[:server_id]}",
      { message: "#{current_user.username} has left the chat room" }
    )
    Rails.logger.info("Stopped streaming for user #{current_user.id} on server #{params[:server_id]}")
  end
end