class MessagesController < ApplicationController
  def create
    @server = Server.find(params[:server_id])
    @message = @server.messages.new(message_params)
    @message.user = current_user
    if @message.save
      ActionCable.server.broadcast "server_#{@server.id}_channel", render_message(@message)
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
