class NpcTaskController < ApplicationController
  def show
    @game = Game.find(params[:id])
    @shard_balance = current_user.shard_account.balance
  end

  def chat
    user_message = params[:message]&.strip&.downcase

    if user_message.nil?
      topics = ["nature", "pop culture", "history", "technology", "science", "animals", "jokes", "movies"]
      random_topic = topics.sample

      client = OpenAI::Client.new
      response = client.chat(
        parameters: {
          model: 'gpt-3.5-turbo',
          messages: [
            { role: 'system', content: "You are an NPC who generates riddles, trivia questions, and their correct answers. Be creative. The riddles and questions should be related to the topic: #{random_topic}." },
            { role: 'user', content: 'Give me a riddle and also include the correct answer in this format: {"riddle": "your riddle", "answer": "correct answer"}' }
          ],
          max_tokens: 100
        }
      )
      npc_response = response.dig('choices', 0, 'message', 'content')

      riddle_data = JSON.parse(npc_response) rescue nil
      if riddle_data && riddle_data["riddle"] && riddle_data["answer"]
        session[:current_riddle] = riddle_data["riddle"]
        session[:correct_answer] = riddle_data["answer"].downcase.strip
        render json: { npc_message: riddle_data["riddle"] }
      else
        render json: { error: "Failed to generate a valid riddle." }, status: :internal_server_error
      end
    else
      current_riddle = session[:current_riddle]
      correct_answer = session[:correct_answer]

      if current_riddle.nil? || correct_answer.nil?
        render json: { error: "Riddle session data missing. Please refresh to get a new riddle." }, status: :internal_server_error
        return
      end

      client = OpenAI::Client.new
      response = client.chat(
        parameters: {
          model: 'gpt-3.5-turbo',
          messages: [
            { role: 'system', content: 'You are an NPC who validates answers to riddles. Respond with either "Correct" or "Wrong".' },
            { role: 'assistant', content: "Riddle: #{current_riddle}" },
            { role: 'user', content: "Answer: #{user_message}" }
          ],
          max_tokens: 50
        }
      )
      npc_message = response.dig('choices', 0, 'message', 'content')

      if npc_message&.downcase&.include?("correct")
        shard_account = current_user.shard_account
        shard_account.balance += 4
        shard_account.save!
        new_shard_balance = shard_account.balance
        render json: { npc_message: "Correct! The answer is #{correct_answer}. Well done!", new_shard_balance: new_shard_balance }
      else
        shard_account = current_user.shard_account
        shard_account.balance = [shard_account.balance - 2, 0].max
        shard_account.save!
        new_shard_balance = shard_account.balance
        render json: { npc_message: "Wrong! The answer is #{correct_answer}!", new_shard_balance: new_shard_balance }
      end
    end
  rescue JSON::ParserError => e
    Rails.logger.debug "JSON::ParserError: #{e.message}"
    render json: { error: "Failed to parse OpenAI response: #{e.message}" }, status: :internal_server_error
  rescue StandardError => e
    Rails.logger.debug "StandardError: #{e.message}"
    render json: { error: "Something went wrong: #{e.message}" }, status: :internal_server_error
  end




end
