require 'rails_helper'

RSpec.describe "MessagesController", type: :request do
  let(:user) { create(:user) }
  let(:server) { create(:server, creator: user) }
  let!(:membership) { Membership.find_or_create_by(user: user, server: server) } # Ensure no duplicate creation
  let(:valid_params) { { message: { content: "Hello, World!" } } }
  let(:invalid_params) { { message: { content: "" } } }

  before do
    sign_in user # Assuming Devise is used for authentication
  end

  describe "POST /servers/:server_id/messages" do
    context "with valid parameters" do
      it "creates a new message and broadcasts it" do
        expect {
          post server_messages_path(server), params: valid_params
        }.to change(Message, :count).by(1)

        expect(response).to have_http_status(:no_content)

        message = Message.last
        expect(message.content).to eq("Hello, World!")
        expect(message.user).to eq(user)

        # Test the broadcasting
        allow(ActionCable.server).to receive(:broadcast)
        post server_messages_path(server), params: valid_params
        expect(ActionCable.server).to have_received(:broadcast).with(
          "server_#{server.id}", hash_including(message: a_string_including("Hello, World!"))
        )
      end
    end

    context "with invalid parameters" do
      it "does not create a new message and returns an error" do
        expect {
          post server_messages_path(server), params: invalid_params
        }.not_to change(Message, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq("error" => "Message could not be sent")
      end
    end

    context "when the user is not a member of the server" do
      let(:another_user) { create(:user) }

      before do
        sign_in another_user
      end

      it "raises a record not found error" do
        expect {
          post server_messages_path(server), params: valid_params
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
