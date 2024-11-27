require 'rails_helper'

RSpec.describe ServerChannel, type: :channel do
  let!(:mystery_box) { create(:item, item_name: "Mystery Box", item_type: "box", item_attributes: {}) }
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
        }.to change { Membership.count }.by(1)

        expect(subscription).to be_confirmed
        expect(Membership.where(user: user, server: server).exists?).to be_truthy
      end
    end

    context 'when the user is already a member' do
      before do
        Membership.find_or_create_by!(user: user, server: server)
      end

      it 'successfully subscribes without creating a duplicate membership' do
        expect {
          subscribe(server_id: server.id)
        }.not_to change { Membership.count }

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

        # Check that the subscription was rejected
        expect(subscription).to be_rejected

        # Ensure no streams were created
        expect(subscription.streams).to be_empty
      end
    end
  end

  describe 'unsubscribed' do
    before do
      Rails.cache.write("server_#{server.id}_online_users", Set.new([user.id]))
      Membership.find_or_create_by!(user: user, server: server)
      subscribe(server_id: server.id)
    end

    it 'removes the user from the online users cache and broadcasts a leave message' do
      expect {
        unsubscribe
      }.to have_broadcasted_to("server_#{server.id}")
             .with(type: 'system', message: "#{user.username} has left the chat room.<br>")

      expect(Rails.cache.fetch("server_#{server.id}_online_users")).not_to include(user.id)
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

  describe 'broadcast_status' do
    before do
      Membership.find_or_create_by!(user: user, server: server)
      subscribe(server_id: server.id)
    end

    let(:invalid_status) { 'busy' }

    it 'logs a warning and does not broadcast when the status is invalid' do
      expect(Rails.logger).to receive(:warn).at_least(:once).with("Invalid status '#{invalid_status}' for user #{user.id} in server #{server.id}")

      # Call the method directly
      subscription.broadcast_status(user.id, invalid_status, server.id)

      expect {
        subscription.broadcast_status(user.id, invalid_status, server.id)
      }.not_to have_broadcasted_to("server_#{server.id}")
    end

    it 'broadcasts status when the status is valid' do
      valid_status = 'online'

      expect {
        subscription.broadcast_status(user.id, valid_status, server.id)
      }.to have_broadcasted_to("server_#{server.id}")
             .with(type: 'status', user_id: user.id, status: valid_status)
    end
  end

end