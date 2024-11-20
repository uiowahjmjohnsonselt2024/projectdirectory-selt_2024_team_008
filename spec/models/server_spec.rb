require 'rails_helper'

RSpec.describe Server, type: :model do
  let(:user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:server) { create(:server, creator: user) }

  describe 'Associations' do
    it { should belong_to(:creator).class_name('User') }
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:users).through(:memberships) }
    it { should have_many(:messages).dependent(:destroy) }
  end

  describe 'Callbacks' do
    it 'adds the creator to memberships after creation' do
      expect(server.memberships.exists?(user: user)).to be_truthy
    end

    it 'logs an error if adding the creator to memberships fails' do
      allow(server.memberships).to receive(:create).and_raise(StandardError, 'Test error')
      expect(Rails.logger).to receive(:error).with(/Failed to add creator to memberships/)
      server.send(:add_creator_to_memberships)
    end
  end

  describe '#user_can_access?' do
    it 'returns true if the user is a member of the server' do
      Membership.find_or_create_by(user: user, server: server)
      expect(server.user_can_access?(user)).to be_truthy
    end

    it 'returns false if the user is not a member of the server' do
      expect(server.user_can_access?(another_user)).to be_falsey
    end
  end

  describe '#remove_user' do
    context 'when the user is a member of the server' do
      before { Membership.find_or_create_by(user: another_user, server: server) }

      it 'removes the user from the server' do
        expect { server.remove_user(another_user) }.to change { server.memberships.count }.by(-1)
      end

      it 'logs the removal of the user' do
        expect(Rails.logger).to receive(:info).with(/Removing user #{another_user.id} from server #{server.id}/)
        server.remove_user(another_user)
      end
    end

    context 'when the user is not a member of the server' do
      it 'logs a warning message' do
        expect(Rails.logger).to receive(:warn).with(/Attempted to remove user #{another_user.id} from server #{server.id}, but no membership found/)
        server.remove_user(another_user)
      end
    end
  end
end
