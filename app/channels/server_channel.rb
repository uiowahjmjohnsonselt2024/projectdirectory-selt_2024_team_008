class ServerChannel < ApplicationCable::Channel

  def subscribed
    server = Server.find_by(id: params[:server_id])

    if server && current_user
      stop_all_streams
      stream_from "server_#{params[:server_id]}"

      # Add user to the online users cache
      online_users = Rails.cache.fetch("server_#{server.id}_online_users", raw: true) { Set.new }
      unless online_users.include?(current_user.id)
        online_users.add(current_user.id)
        Rails.cache.write("server_#{server.id}_online_users", online_users, raw: true)

        # Broadcast join message
        ActionCable.server.broadcast(
          "server_#{params[:server_id]}",
          { type: 'system', message: "#{current_user.username} has joined the chat room.<br>" }
        )

        # Use broadcast_status to send online status
        broadcast_status(current_user.id, 'online', params[:server_id])

        # Broadcast all currently online users' statuses to the new user
        online_users.each do |user_id|
          broadcast_status(user_id, 'online', params[:server_id])
        end
      end
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams

    server = Server.find_by(id: params[:server_id])

    if server && current_user
      online_users = Rails.cache.fetch("server_#{server.id}_online_users", raw: true) { Set.new }
      if online_users.include?(current_user.id)
        online_users.delete(current_user.id)
        Rails.cache.write("server_#{server.id}_online_users", online_users, raw: true)

        # Broadcast leave message
        ActionCable.server.broadcast(
          "server_#{params[:server_id]}",
          { type: 'system', message: "#{current_user.username} has left the chat room.<br>" }
        )

        # Use broadcast_status to send offline status
        broadcast_status(current_user.id, 'offline', params[:server_id])
      end
    end
  end

  # Handle normal chat messages
  def send_message(data)
    server_id = params[:server_id]
    broadcast_data = {
      type: 'message', # Ensure type is included
      message: "<p><strong>#{current_user.username}:</strong> #{data['message']}</p>"
    }

    Rails.logger.info("Broadcasting message: #{broadcast_data}")
    ActionCable.server.broadcast("server_#{server_id}", broadcast_data)
  end

  def broadcast_status(user_id, status, server_id, extra_data = {})
    valid_statuses = %w[online offline]

    unless valid_statuses.include?(status)
      Rails.logger.warn("Invalid status '#{status}' for user #{user_id} in server #{server_id}")
      return
    end

    broadcast_data = { type: 'status', user_id: user_id, status: status }.merge(extra_data)

    Rails.logger.info("Broadcasting status update: #{broadcast_data}")
    ActionCable.server.broadcast("server_#{server_id}", broadcast_data)
  end

end