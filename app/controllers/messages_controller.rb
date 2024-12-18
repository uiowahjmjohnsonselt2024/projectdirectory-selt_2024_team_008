class MessagesController < ApplicationController
  def create
    @server = Server.find(params[:server_id])
    raise ActiveRecord::RecordNotFound unless @server.memberships.exists?(user: current_user)

    @message = @server.messages.new(message_params)
    @message.user = current_user
    current_user.update(last_seen_at: Time.current)

    if @message.save
      broadcast_message = render_message(@message)
      Rails.logger.info("Broadcasting message: #{broadcast_message}")
      ActionCable.server.broadcast(
        "server_#{@server.id}",
        { message: broadcast_message }
      )
      head :no_content
    else
      Rails.logger.error("Message could not be saved: #{@message.errors.full_messages}")
      render json: { error: "Message could not be sent" }, status: :unprocessable_entity
    end

  end

  def index
    @server = Server.find(params[:server_id])
    @messages = @server.messages.order(:created_at)

    respond_to do |format|
      format.html do
        render partial: 'messages/message', collection: @messages
      end
      format.json do
        render json: @messages.as_json(
          only: [:id, :content, :created_at],
          include: { user: { only: [:id, :username] } }
        )
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def render_message(message)
    ApplicationController.renderer.render(partial: 'messages/message', locals: { message: message })
  end

end