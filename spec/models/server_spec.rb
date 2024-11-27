require 'rails_helper'

RSpec.describe Server, type: :model do
  let(:creator) { create(:user) }
  let(:server) { create(:server, creator: creator) }
  let(:user) { create(:user) }

  describe "#remove_user" do
    context "when the user is a member of the server" do
      before do
        server.memberships.create(user: user)
      end

      it "removes the user from the server" do
        expect {
          server.remove_user(user)
        }.to change { server.memberships.exists?(user_id: user.id) }.from(true).to(false)
      end

      it "logs the removal of the user" do
        allow(Rails.logger).to receive(:info)
        server.remove_user(user)
        expect(Rails.logger).to have_received(:info).with("Removing user #{user.id} from server #{server.id}")
      end
    end

    context "when the user is not a member of the server" do
      it "does not change the memberships" do
        expect {
          server.remove_user(user)
        }.not_to change { server.memberships.count }
      end

      it "logs a warning message" do
        allow(Rails.logger).to receive(:warn)
        server.remove_user(user)
        expect(Rails.logger).to have_received(:warn).with("Attempted to remove user #{user.id} from server #{server.id}, but no membership found")
      end
    end
  end

  describe "#user_can_access?" do
    context "when the user is a member of the server" do
      before do
        server.memberships.create(user: user)
      end

      it "returns true" do
        allow(Rails.logger).to receive(:info)
        expect(server.user_can_access?(user)).to eq(true)
        expect(Rails.logger).to have_received(:info).with("Checking access for user #{user.id} on server #{server.id}: true")
      end
    end

    context "when the user is not a member of the server" do
      it "returns false" do
        allow(Rails.logger).to receive(:info)
        expect(server.user_can_access?(user)).to eq(false)
        expect(Rails.logger).to have_received(:info).with("Checking access for user #{user.id} on server #{server.id}: false")
      end
    end

    context "when the user is nil" do
      it "returns false" do
        expect(server.user_can_access?(nil)).to eq(false)
      end
    end
  end

  describe "#prevent_creator_nullification" do
    context "when the server's creator_id is set to nil" do
      it "raises an ActiveRecord::Rollback error" do
        server.creator_id = nil
        expect {
          server.send(:prevent_creator_nullification)
        }.to raise_error(ActiveRecord::Rollback, "Cannot nullify creator_id during server destruction")
      end
    end

    context "when the server's creator_id is present" do
      it "does not raise an error" do
        expect {
          server.send(:prevent_creator_nullification)
        }.not_to raise_error
      end
    end
  end

  describe "#add_creator_to_memberships" do
    context "when the creator is not in memberships" do
      before do
        server.memberships.delete_all # Ensures the creator is not already in memberships
      end

      it "adds the creator to memberships" do
        expect(server.memberships.exists?(user: creator)).to eq(false)
        expect {
          server.send(:add_creator_to_memberships)
        }.to change { server.memberships.exists?(user: creator) }.from(false).to(true)
      end
    end

    context "when an error occurs while adding the creator" do
      before do
        allow(server.memberships).to receive(:exists?).with(user: creator).and_return(false) # Ensure membership check passes
        allow(server.memberships).to receive(:create!).and_raise(StandardError, "Test error") # Mock error
        allow(Rails.logger).to receive(:error) # Mock logger
      end

      it "logs the error" do
        # Trigger the method
        server.send(:add_creator_to_memberships)

        # Verify logger was called
        expect(Rails.logger).to have_received(:error).with("Failed to add creator to memberships for server #{server.id}: Test error")
      end
    end
  end
end