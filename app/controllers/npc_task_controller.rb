class NpcTaskController < ApplicationController
  def show
    @game = Game.find(params[:id])
    @shard_balance = current_user.shard_account.balance
  end

  def chat
    user_message = params[:message]&.strip&.downcase

    if user_message.nil?
      # Array of topics for riddles
      topics = ["nature", "pop culture", "history", "technology", "science", "animals", "jokes", "movies"]
      random_topic = topics.sample # Select a random topic

      # Generate a new riddle with the selected topic
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

      # Parse the riddle and answer
      riddle_data = JSON.parse(npc_response) rescue nil
      if riddle_data && riddle_data["riddle"] && riddle_data["answer"]
        # Store the riddle and answer in the session (or database)
        session[:current_riddle] = riddle_data["riddle"]
        session[:correct_answer] = riddle_data["answer"].downcase.strip
        render json: { npc_message: riddle_data["riddle"] }
      else
        render json: { error: "Failed to generate a valid riddle." }, status: :unprocessable_entity
      end
    else
      # Validate the user's answer
      current_riddle = session[:current_riddle]
      correct_answer = session[:correct_answer]

      if current_riddle.nil? || correct_answer.nil?
        render json: { npc_message: "Something went wrong. Please refresh to get a new riddle." }, status: :unprocessable_entity
        return
      end

      # Check the user's answer
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
        # Correct answer logic
        shard_account = current_user.shard_account
        shard_account.balance += 4
        shard_account.save!
        new_shard_balance = shard_account.balance

        render json: { npc_message: "Correct! The answer is #{correct_answer}. Well done!", new_shard_balance: new_shard_balance }
      else
        # Incorrect answer logic
        shard_account = current_user.shard_account
        shard_account.balance -= 2
        shard_account.save!
        new_shard_balance = shard_account.balance
        render json: { npc_message: "Wrong! The answer is #{correct_answer}!", new_shard_balance: new_shard_balance }
        #render json: { npc_message: "Wrong. The answer is not correct. Come back later" }
      end
    end
  rescue StandardError => e
    render json: { error: "Something went wrong: #{e.message}" }, status: :internal_server_error
  end
end
