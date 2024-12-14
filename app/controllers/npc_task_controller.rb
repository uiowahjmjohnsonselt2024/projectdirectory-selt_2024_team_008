class NpcTaskController < ApplicationController
  def show
    @game = Game.find(params[:id])
    @shard_balance = current_user.shard_account.balance
  end
  def chat

    user_message = params[:message]
    if user_message.nil?
      # If no user message, provide a riddle (initial page load)
      client = OpenAI::Client.new
      response = client.chat(
        parameters: {
          model: 'gpt-3.5-turbo',
          messages: [
            { role: 'system', content: 'You are an NPC who gives riddles.' },
            { role: 'user', content: 'Give me a riddle.' }
          ],
          max_tokens: 50
        }
      )
      npc_message = response.dig('choices', 0, 'message', 'content')
      render json: { npc_message: npc_message }
    else
      # Validate user's answer
      client = OpenAI::Client.new
      response = client.chat(
        parameters: {
          model: 'gpt-3.5-turbo',
          messages: [
            { role: 'system', content: 'You are an NPC who validates answers to riddles.' },
            { role: 'user', content: user_message }
          ],
          max_tokens: 50
        }
      )
      npc_message = response.dig('choices', 0, 'message', 'content')

      if npc_message&.downcase&.include?("correct")
        shard_account = current_user.shard_account
        shard_account.balance += 50
        shard_account.save!
        Rails.logger.info("ShardAccount After Increment: #{shard_account.balance}")
        new_shard_balance = shard_account.balance
      end
      render json: { npc_message: npc_message, new_shard_balance: new_shard_balance }
    end
  rescue StandardError => e
    render json: { error: "Something went wrong: #{e.message}" }, status: :internal_server_error
  end
end
