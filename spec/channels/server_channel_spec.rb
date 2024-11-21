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
        expect {
          subscribe(server_id: server.id)
        }.to change { Membership.where(user: user, server: server).count }.by(1)

        expect(subscription).to be_confirmed
      end
    end

    context 'when the user is already a member' do
      before do
        Membership.find_or_create_by!(user: user, server: server)
      end

      it 'successfully subscribes without creating a duplicate membership' do
        expect {
          subscribe(server_id: server.id)
        }.not_to change { Membership.where(user: user, server: server).count }

        expect(subscription).to be_confirmed
      end
    end

    context 'when the server does not exist' do
      it 'rejects the subscription' do
        subscribe(server_id: nil)
        expect(subscription).to be_rejected
      end
    end

    context 'when current_user is nil' do
      before do
        stub_connection current_user: nil
      end

      it 'rejects the subscription' do
        subscribe(server_id: server.id)
        expect(subscription).to be_rejected
      end
    end

    context 'when user does not have access to the server' do
      before do
        allow_any_instance_of(Server).to receive(:user_can_access?).and_return(false)
      end

      it 'rejects the subscription' do
        subscribe(server_id: server.id)
        expect(subscription).to be_rejected
      end
    end
  end

  describe 'unsubscribed' do
    before do
      Membership.find_or_create_by!(user: user, server: server)
      subscribe(server_id: server.id)
    end

    it 'removes the user from the online users cache and broadcasts a leave message' do
      Rails.cache.write("server_#{server.id}_online_users", Set.new([user.id]))

      expect {
        unsubscribe
      }.to have_broadcasted_to("server_#{server.id}")
             .with(type: 'system', message: "#{user.username} has left the chat room.<br>")

      expect(Rails.cache.fetch("server_#{server.id}_online_users", raw: true)).to eq(Set.new)
    end
  end

  describe 'receiving messages' do
    before do
      Membership.find_or_create_by!(user: user, server: server)
      subscribe(server_id: server.id)
    end

    it 'streams messages to the channel' do
      expect {
        perform :send_message, { message: 'Hello, World!' }
      }.to have_broadcasted_to("server_#{server.id}")
             .with(type: 'message', message: "<p><strong>testuser:</strong> Hello, World!</p>")
    end
  end
end