require 'rails_helper'

RSpec.describe NpcTaskController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { FactoryBot.create(:user) } # Use a valid user factory
  let(:mock_openai_client) { instance_double(OpenAI::Client) }

  before do
    sign_in user
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
      it "returns a bad request error" do
        post :chat, params: {}, as: :json
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("Message parameter is required")
      end
    end
  end
end
