class MessagesController < ApplicationController
  def create
    @server = Server.find(params[:server_id])
    @message = @server.messages.new(message_params)
    @message.user = current_user
    if @message.save
      ActionCable.server.broadcast "server_#{@server.id}", render_message(@message)
      head :no_content
    else
      render json: { error: "Message could not be sent" }, status: :unprocessable_entity
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
