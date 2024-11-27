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
  end

  describe 'subscribed' do
    context 'when Membership creation fails' do
      before do
        # Stub the logger before triggering the error
        allow(Rails.logger).to receive(:error)

        # Mock Membership to raise ActiveRecord::RecordInvalid
        allow(Membership).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordInvalid.new(Membership.new))
      end

      it 'logs an error and rejects the subscription' do
        subscribe(server_id: server.id)

        expect(Rails.logger).to have_received(:error).with(/Failed to create membership for user #{user.id}:/).once
        expect(subscription).to be_rejected
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
             .with(type: 'system', message: "#{user.username} has left the server.")

      expect(Rails.cache.fetch("server_#{server.id}_online_users")).not_to include(user.id)
    end
  end

  describe 'receiving messages' do
    before do
      Membership.find_or_create_by!(user: user, server: server)
      subscribe(server_id: server.id)
    end

    it 'broadcasts a valid message to the channel' do
      expect {
        perform :send_message, { message: 'Hello, World!' }
      }.to have_broadcasted_to("server_#{server.id}")
             .with(type: 'message', message: "<p><strong>testuser:</strong> Hello, World!</p>")
    end

    it 'logs an error when message saving fails' do
      allow_any_instance_of(Message).to receive(:save).and_return(false)
      expect(Rails.logger).to receive(:error).with(/Failed to save message:/)
      perform :send_message, { message: 'Invalid message' }
    end
  end

  describe 'broadcast_status' do
    before do
      # Subscribe to the channel to satisfy the "Must be subscribed!" requirement
      subscribe(server_id: server.id)
    end

    it 'logs a warning and does not broadcast when the status is invalid' do
      invalid_status = 'busy'

      allow(Rails.logger).to receive(:warn)

      # Trigger broadcast_status by simulating an invalid status change
      subscription.send(:broadcast_status, user.id, invalid_status, server.id)

      expect(Rails.logger).to have_received(:warn)
                                .with("Invalid status '#{invalid_status}' for user #{user.id} in server #{server.id}")
                                .once

      expect do
        subscription.send(:broadcast_status, user.id, invalid_status, server.id)
      end.not_to have_broadcasted_to("server_#{server.id}")
    end

    it 'broadcasts status when the status is valid' do
      valid_status = 'online'

      expect do
        subscription.send(:broadcast_status, user.id, valid_status, server.id)
      end.to have_broadcasted_to("server_#{server.id}")
               .with(type: 'status', user_id: user.id, status: valid_status)
    end
  end

  describe 'cache operations' do
    context 'when adding a user to the online cache' do
      it 'updates the cache correctly' do
        subscribe(server_id: server.id)
        online_users = Rails.cache.fetch("server_#{server.id}_online_users")
        expect(online_users).to include(user.id)
      end
    end

    context 'when removing a user from the online cache' do
      it 'updates the cache correctly' do
        Rails.cache.write("server_#{server.id}_online_users", Set.new([user.id]))
        subscribe(server_id: server.id)
        unsubscribe
        online_users = Rails.cache.fetch("server_#{server.id}_online_users")
        expect(online_users).not_to include(user.id)
      end
    end
  end
end