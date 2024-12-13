class ServerChannel < ApplicationCable::Channel
  def subscribed
    server = Server.find_by(id: params[:server_id])

    if server && current_user
      Membership.transaction do
        membership = Membership.lock("FOR UPDATE").find_by(user: current_user, server: server)

        # Create a server-only membership if none exists
        membership ||= Membership.create!(user: current_user, server: server)
      end

      stop_all_streams
      stream_from "server_#{server.id}"

      add_user_to_online_cache(server)

      # Notify about the user joining
      broadcast_system_message("#{current_user.username} has joined the server.", server.id)
      broadcast_status(current_user.id, 'online', server.id)

      # Broadcast online statuses of all users to the new subscriber
      broadcast_all_online_statuses(server)
    else
      reject
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create membership for user #{current_user.id}: #{e.message}")
    reject
  end

  def unsubscribed
    stop_all_streams

    server = Server.find_by(id: params[:server_id])
    return unless server && current_user

    remove_user_from_online_cache(server)

    # Notify about the user leaving
    broadcast_system_message("#{current_user.username} has left the server.", server.id)
    broadcast_status(current_user.id, 'offline', server.id)
  end

  def send_message(data)
    server = Server.find_by(id: params[:server_id])
    return unless server

    message = server.messages.new(content: data['message'], user: current_user)

    if message.save
      broadcast_message(message, server.id)
    else
      Rails.logger.error("Failed to save message: #{message.errors.full_messages}")
    end
  end

  private

  def broadcast_system_message(message, server_id)
    ActionCable.server.broadcast(
      "server_#{server_id}",
      { type: 'system', message: message }
    )
  end

  def broadcast_message(message, server_id)
    broadcast_data = {
      type: 'message',
      message: "<p><strong>#{message.user.username}:</strong> #{message.content}</p>"
    }

    Rails.logger.info("Broadcasting message: #{broadcast_data}")
    ActionCable.server.broadcast("server_#{server_id}", broadcast_data)
  end

  def broadcast_status(user_id, status, server_id)
    valid_statuses = %w[online offline]
    unless valid_statuses.include?(status)
      Rails.logger.warn("Invalid status '#{status}' for user #{user_id} in server #{server_id}")
      return
    end

    broadcast_data = { type: 'status', user_id: user_id, status: status }
    Rails.logger.info("Broadcasting status update: #{broadcast_data}")
    ActionCable.server.broadcast("server_#{server_id}", broadcast_data)
  end

  def add_user_to_online_cache(server)
    online_users = Rails.cache.fetch("server_#{server.id}_online_users") { Set.new }
    unless online_users.include?(current_user.id)
      online_users.add(current_user.id)
      Rails.cache.write("server_#{server.id}_online_users", online_users)
    end
  end

  def remove_user_from_online_cache(server)
    online_users = Rails.cache.fetch("server_#{server.id}_online_users") { Set.new }
    if online_users.include?(current_user.id)
      online_users.delete(current_user.id)
      Rails.cache.write("server_#{server.id}_online_users", online_users)
    end
  end

  def broadcast_all_online_statuses(server)
    online_users = Rails.cache.fetch("server_#{server.id}_online_users") { Set.new }
    online_users.each do |user_id|
      broadcast_status(user_id, 'online', server.id)
    end
  end
end