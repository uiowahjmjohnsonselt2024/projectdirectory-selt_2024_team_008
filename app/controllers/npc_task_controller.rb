class NpcTaskController < ApplicationController
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

  def wordle_task
    user_message = params[:message]

    if user_message.nil?
      # Initial page load: provide game instructions and a starting message
      client = OpenAI::Client.new
      response = client.chat(
        parameters: {
          model: 'gpt-3.5-turbo',
          messages: [
            { role: 'system', content: 'You are an NPC hosting a Wordle-like game. The user guesses a word, and you provide feedback until they win.' },
            { role: 'user', content: 'Start the Wordle game. Give me instructions and the first response.' }
          ],
          max_tokens: 100
        }
      )
      npc_message = response.dig('choices', 0, 'message', 'content')
      render json: { npc_message: npc_message }
    else
      # Process user's guess
      client = OpenAI::Client.new
      response = client.chat(
        parameters: {
          model: 'gpt-3.5-turbo',
          messages: [
            { role: 'system', content: 'You are an NPC hosting a Wordle-like game. Validate the user guess and respond with feedback until they win.' },
            { role: 'user', content: user_message }
          ],
          max_tokens: 50
        }
      )

      npc_message = response.dig('choices', 0, 'message', 'content')

      if npc_message&.downcase&.include?("congratulations")
        # Game ends when the response includes "Congratulations"
        shard_account = current_user.shard_account
        shard_account.balance += 50
        shard_account.save!
        Rails.logger.info("ShardAccount After Increment: #{shard_account.balance}")
        new_shard_balance = shard_account.balance
        render json: { npc_message: npc_message, new_shard_balance: new_shard_balance, game_over: true }
      else
        # Continue the game
        render json: { npc_message: npc_message, game_over: false }
      end
    end
  rescue StandardError => e
    render json: { error: "Something went wrong: #{e.message}" }, status: :internal_server_error
  end

end
