require 'rails_helper'

RSpec.describe ServerChannel, type: :channel do
  let(:user) { create(:user, username: 'testuser', email: 'test_user@example.com') }
  let(:server) { create(:server, name: 'Test Server', creator: user) }

  before do
    stub_connection current_user: user
  end

  describe 'subscribing to the channel' do
    context 'when the user is not already a member' do
      it 'successfully subscribes and creates a membership' do
        subscribe(server_id: server.id)

        expect(subscription).to be_confirmed
        expect(Membership.exists?(user: user, server: server)).to be_truthy
      end
    end

    context 'when the user is already a member' do
      it 'successfully subscribes without creating a duplicate membership' do
        Membership.find_or_create_by!(user: user, server: server)

        subscribe(server_id: server.id)

        expect(subscription).to be_confirmed
        expect(Membership.where(user: user, server: server).count).to eq(1)
      end
    end

    context 'when the server does not exist' do
      it 'rejects subscription' do
        subscribe(server_id: nil)

        expect(subscription).to be_rejected
      end
    end

    context 'when current_user is nil' do
      it 'rejects subscription' do
        stub_connection current_user: nil

        subscribe(server_id: server.id)

        expect(subscription).to be_rejected
      end
    end

    context 'when user does not have access to the server' do
      it 'rejects subscription' do
        allow_any_instance_of(Server).to receive(:user_can_access?).and_return(false)

        subscribe(server_id: server.id)

        expect(subscription).to be_rejected
      end
    end
  end

  describe 'unsubscribed' do
    it 'broadcasts a message when the user unsubscribes' do
      Membership.find_or_create_by!(user: user, server: server)

      subscribe(server_id: server.id)

      expect {
        unsubscribe
      }.to have_broadcasted_to("server_#{server.id}")
             .with(message: "#{user.username} has left the chat room")
    end
  end

  describe 'receiving messages' do
    it 'streams messages to the channel' do
      Membership.find_or_create_by!(user: user, server: server)

      subscribe(server_id: server.id)

      message = create(:message, user: user, server: server, content: 'Hello, World!')

      expect {
        ActionCable.server.broadcast("server_#{server.id}", { message: message.content })
      }.to have_broadcasted_to("server_#{server.id}")
             .with(message: message.content)
    end
  end
end
