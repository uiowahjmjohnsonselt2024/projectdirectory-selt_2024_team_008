require 'rails_helper'

RSpec.describe NpcTaskController, type: :controller do
  include Devise::Test::ControllerHelpers

  let!(:user) do
    user = User.create!(username: 'test_user', email: 'test@example.com', password: 'password')
    ShardAccount.create!(user: user, balance: 0) # Initialize with 0 shards
    user
  end

  let(:shard_account) { user.shard_account }
  let(:mock_openai_client) { instance_double(OpenAI::Client) }

  before do
    sign_in user
    allow(controller).to receive(:current_user).and_return(user)
    allow(user).to receive(:shard_account).and_return(shard_account)
    allow(OpenAI::Client).to receive(:new).and_return(mock_openai_client)
  end

  describe "POST #chat" do
    context "when no message is sent (initial load)" do
      it "returns a riddle and stores it in the session" do
        allow(mock_openai_client).to receive(:chat).and_return({
                                                                 'choices' => [
                                                                   { 'message' => { 'content' => '{"riddle": "What has keys but no locks?", "answer": "a piano"}' } }
                                                                 ]
                                                               })

        post :chat, params: { message: nil }, as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body["npc_message"]).to eq("What has keys but no locks?")
        expect(session[:current_riddle]).to eq("What has keys but no locks?")
        expect(session[:correct_answer]).to eq("a piano")
      end
    end

    context "when the user's answer is correct" do
      before do
        session[:current_riddle] = "What has keys but no locks?"
        session[:correct_answer] = "a piano"
      end

      it "awards 4 shards to the user" do
        allow(mock_openai_client).to receive(:chat).and_return({
                                                                 'choices' => [
                                                                   { 'message' => { 'content' => 'Correct!' } }
                                                                 ]
                                                               })

        post :chat, params: { message: "A piano" }, as: :json

        expect(response).to have_http_status(:success)
        expect(user.shard_account.reload.balance).to eq(4)
        body = JSON.parse(response.body)
        expect(body["npc_message"]).to include("Correct")
      end
    end

    context "when the user's answer is incorrect" do
      before do
        session[:current_riddle] = "What has keys but no locks?"
        session[:correct_answer] = "a piano"
      end

      it "deducts 2 shards from the user" do
        allow(mock_openai_client).to receive(:chat).and_return({
                                                                 'choices' => [
                                                                   { 'message' => { 'content' => 'Wrong!' } }
                                                                 ]
                                                               })

        # Set initial shard balance to test deduction
        shard_account.update!(balance: 10)

        post :chat, params: { message: "A door" }, as: :json

        expect(response).to have_http_status(:success)
        expect(user.shard_account.reload.balance).to eq(8) # Deducted 2 shards
        body = JSON.parse(response.body)
        expect(body["npc_message"]).to include("Wrong")
        expect(body["new_shard_balance"]).to eq(8)
      end
    end


    context "when the OpenAI API returns an error" do
      it "returns an error message with status 500" do
        allow(mock_openai_client).to receive(:chat).and_raise(StandardError, "OpenAI error")

        post :chat, params: { message: "What is the riddle?" }, as: :json

        puts "Response status: #{response.status}"
        puts "Response body: #{response.body}"

        expect(response).to have_http_status(:internal_server_error) # Expect 500
        body = JSON.parse(response.body)
        expect(body["error"]).to include("Riddle session data missing")
      end
    end







    context "when a new riddle is generated with a random topic" do
      it "includes the topic in the OpenAI API prompt" do
        topics = ["nature", "pop culture", "history", "technology", "science", "animals", "jokes", "movies"]
        allow(mock_openai_client).to receive(:chat) do |params|
          topic_in_prompt = topics.any? { |topic| params[:parameters][:messages][0][:content].include?(topic) }
          expect(topic_in_prompt).to be true

          {
            'choices' => [
              { 'message' => { 'content' => '{"riddle": "What runs but never walks?", "answer": "a river"}' } }
            ]
          }
        end

        post :chat, params: { message: nil }, as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body["npc_message"]).to eq("What runs but never walks?")
      end
    end
  end
end
