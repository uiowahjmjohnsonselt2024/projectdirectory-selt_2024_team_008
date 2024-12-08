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
    context "when a valid message is sent" do
      it "returns a valid NPC response" do
        allow(mock_openai_client).to receive(:chat).and_return({
                                                                 'choices' => [
                                                                   { 'message' => { 'content' => 'Here is a riddle for you!' } }
                                                                 ]
                                                               })
        post :chat, params: { message: "What is the riddle?" }, as: :json
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)["npc_message"]).to eq("Here is a riddle for you!")
      end
    end

    context "when the OpenAI API returns an error" do
      it "returns an error message" do
        allow(mock_openai_client).to receive(:chat).and_raise(StandardError, "OpenAI error")

        post :chat, params: { message: "What is the riddle?" }, as: :json
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)["error"]).to include("Something went wrong")
      end
    end

    context "when no message is sent" do
      it "returns a riddle on initial load" do
        allow(mock_openai_client).to receive(:chat).with(
          parameters: {
            model: 'gpt-3.5-turbo',
            messages: [
              { role: 'system', content: 'You are an NPC who gives riddles.' },
              { role: 'user', content: 'Give me a riddle.' }
            ],
            max_tokens: 50
          }
        ).and_return({
                       'choices' => [
                         { 'message' => { 'content' => 'Here is a riddle for you!' } }
                       ]
                     })

        post :chat, params: { message: nil }, as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)["npc_message"]).to eq("Here is a riddle for you!")
      end
    end
  end

  #------------------------------------------------------------------------------------------------
  describe "POST #chat" do
    context "when a valid message is sent" do
      it "returns a valid NPC response" do
        allow(mock_openai_client).to receive(:chat).and_return({
                                                                 'choices' => [
                                                                   { 'message' => { 'content' => 'Here is a riddle for you!' } }
                                                                 ]
                                                               })

        post :chat, params: { message: "What is the riddle?" }, as: :json
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)["npc_message"]).to eq("Here is a riddle for you!")
      end
    end

    context "when the user's answer is correct" do
      it "awards 50 shards to the user" do
        # Simulate OpenAI response indicating the answer is correct
        allow(mock_openai_client).to receive(:chat).and_return({
                                                                 'choices' => [
                                                                   { 'message' => { 'content' => 'Correct!' } }
                                                                 ]
                                                               })

        # Send a valid message
        post :chat, params: { message: "A piano" }, as: :json

        # Reload the shard account to check the updated balance
        expect(response).to have_http_status(:success)
        expect(user.shard_account.reload.balance).to eq(50)
      end
    end

    context "when the user's answer is incorrect" do
      it "does not award shards to the user" do
        allow(mock_openai_client).to receive(:chat).and_return({
                                                                 'choices' => [
                                                                   { 'message' => { 'content' => 'Not quite, try again!' } }
                                                                 ]
                                                               })

        post :chat, params: { message: "A door" }, as: :json

        expect(response).to have_http_status(:success)
        expect(shard_account.reload.balance).to eq(0)
      end
    end
  end
end
