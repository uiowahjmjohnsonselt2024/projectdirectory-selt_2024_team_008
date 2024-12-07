class NpcTaskController < ApplicationController
  def chat
    Rails.logger.info("Current User: #{current_user.inspect}")
    Rails.logger.info("ShardAccount: #{current_user.shard_account.inspect}")

    user_message = params[:message]
    if user_message.blank?
      render json: { error: "Message parameter is required" }, status: :bad_request
      return
    end

    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        model: 'gpt-3.5-turbo',
        messages: [
          { role: 'system', content: 'You are an NPC who answers riddles and gives hints.' },
          { role: 'user', content: user_message }
        ],
        max_tokens: 50
      }
    )
    #Rails.logger.info("OpenAI API response: #{response}")
    npc_message = response.dig('choices', 0, 'message', 'content')

    if npc_message&.downcase == "correct!"
      shard_account = current_user.shard_account
      shard_account.balance += 50
      shard_account.save!
    end

    render json: { npc_message: npc_message }
  rescue StandardError => e
    render json: { error: "Something went wrong: #{e.message}" }, status: :internal_server_error
  end
end


