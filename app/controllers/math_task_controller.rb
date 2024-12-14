class MathTaskController < ApplicationController
  def show
    @game = Game.find(params[:id])
    @shard_balance = current_user.shard_account.balance
  end

  def chat

    user_message = params[:message]
    math_message = ""
    if user_message.nil?
      # If no user message, provide a math problem (initial page load)
      solution = 0
      math_type = rand(3) #random number between 0 and 2
      if math_type == 0
        num_one = rand(10..999) #random number between 10 and 999
        num_two = rand(10..999) #random number between 10 and 999
        solution = num_one + num_two
        math_message = "What is #{num_one} + #{num_two}?"
        #math_message = "What is 1 + 2?"

      elsif math_type == 1
        num_one = rand(11..999) #random number between 11 and 999
        num_two = rand(10..(num_one - 1)) #random number at least 10 and less than num_one
        solution = num_one - num_two;
        math_message = "What is #{num_one} - #{num_two}?"
        #math_message = "What is 2 - 1?"
      elsif math_type == 2
        num_one = rand(2..15) #random number between 2 and 15
        num_two = rand(2..15) #random number between 2 and 15
        solution = num_one * num_two
        math_message = "What is #{num_one} * #{num_two}?"
        #math_message = "What is 1 * 2?"
      end
      render json: { math_message: math_message, solution: solution }
    else
      # Validate user's answer
      solution_param = params[:solution]
      user_num = user_message.to_i
      if user_num == 0
        math_message = "You either entered 0 which is wrong or you did not enter a number."
      elsif user_num == solution_param
        shard_account = current_user.shard_account
        shard_account.balance += 50
        shard_account.save!
        Rails.logger.info("ShardAccount After Increment: #{shard_account.balance}")
        new_shard_balance = shard_account.balance
        math_message = "correct"
      else
        math_message = "wrong answer"
      end
      render json: { math_message: math_message, new_shard_balance: new_shard_balance }
    end
  rescue StandardError => e
    render json: { error: "Something went wrong: #{e.message}" }, status: :internal_server_error
  end
end
