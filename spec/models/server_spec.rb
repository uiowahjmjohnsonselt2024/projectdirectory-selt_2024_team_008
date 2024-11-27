require 'rails_helper'

RSpec.describe Server, type: :model do
  let!(:mystery_box) { create(:item, item_name: "Mystery Box", item_type: "box", item_attributes: {}) }
  let!(:creator) { create(:user, username: "creator") }
  let!(:replacement_user) { create(:user, username: "replacement_creator") }
  let!(:server) { create(:server, creator: creator) }

  before do
    server.update!(original_creator_id: creator.id)
    server.memberships.create!(user: replacement_user)
  end

  describe "#remove_user" do
    context "when the user is a member of the server" do

      it "reassigns creator_id to another user" do
        server.remove_user(creator)
        expect(server.creator_id).to eq(replacement_user.id)
      end

      it "falls back to the original_creator_id when no other users are available" do
        server.memberships.where(user: replacement_user).destroy_all
        server.remove_user(creator)
        expect(server.creator_id).to eq(server.original_creator_id)
      end

      it "removes the user from the server" do
        server.messages.where(user: creator).destroy_all
        expect {
          server.remove_user(creator)
        }.to change { server.memberships.exists?(user_id: creator.id) }.from(true).to(false)
      end

      it "removes the user and their related messages" do
        server.messages.create!(content: "Message 1", user: creator)

        expect {
          server.remove_user(creator)
        }.to change { server.memberships.exists?(user: creator) }.from(true).to(false)
                                                              .and change { server.messages.where(user: creator).count }.from(1).to(0)
      end

      it "does not leave orphaned records" do
        server.messages.create!(content: "Test message", user: creator)
        expect {
          server.remove_user(creator)
        }.to change { server.messages.where(user: creator).exists? }.from(true).to(false)
      end

      it "logs the removal of the user" do
        allow(Rails.logger).to receive(:info)
        server.remove_user(creator)
        expect(Rails.logger).to have_received(:info).with("Removing user #{creator.id} from server #{server.id}")
      end
    end

    context "when the user is not a member of the server" do
      it "does not change the memberships" do
        non_member = create(:user, username: "non_member")
        expect {
          server.remove_user(non_member)
        }.not_to change { server.memberships.count }
      end

      it "logs a error message" do
        allow(Rails.logger).to receive(:error)
        allow_any_instance_of(Membership).to receive(:destroy!).and_raise(ActiveRecord::InvalidForeignKey, "Foreign key constraint violated")

        expect {
          server.remove_user(replacement_user)
        }.to raise_error(ActiveRecord::InvalidForeignKey)

        expect(Rails.logger).to have_received(:error).with(
          "Failed to remove membership for user #{replacement_user.id} in server #{server.id}: Foreign key constraint violated"
        )
      end
    end
  end

  describe "#user_can_access?" do
    context "when the user is a member of the server" do

      it "returns true" do
        allow(Rails.logger).to receive(:info)
        expect(server.user_can_access?(creator)).to eq(true)
        expect(Rails.logger).to have_received(:info).with("Checking access for user #{creator.id} on server #{server.id}: true")
      end
    end

    context "when the user is not a member of the server" do
      it "returns false" do
        non_member = create(:user, username: "non_member")
        expect(server.user_can_access?(non_member)).to eq(false)
      end
    end

    context "when the user is nil" do
      it "returns false" do
        expect(server.user_can_access?(nil)).to eq(false)
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

  describe "before_destroy callback: reassign_creator" do
    context "when destroying a server with an existing creator" do
      it "reassigns the creator to another user before destruction" do
        server.send(:reassign_creator)
        expect(server.creator_id).to eq(replacement_user.id)
      end
    end

    context "when destroying a server and only the original creator is valid" do
      before do
        server.memberships.where(user: replacement_user).destroy_all
      end

      it "reassigns the original creator as the server's creator before destruction" do
        expect {
          server.destroy
        }.not_to change { server.creator_id }
      end
    end

    context "when destroying a server with no valid creators" do
      before do
        server.memberships.destroy_all
        server.update!(original_creator_id: nil)
      end

      it "sets the creator_id to nil before destruction" do
        expect {
          server.destroy
        }.to change { server.creator_id }.to(nil)
      end
    end

    context "when destroying a server without affecting other attributes" do
      it "does not delete memberships or messages before destruction" do
        expect {
          server.destroy
        }.to change { server.memberships.count }.to(0)
        expect(server.messages.count).to eq(0)
      end
    end
  end
end