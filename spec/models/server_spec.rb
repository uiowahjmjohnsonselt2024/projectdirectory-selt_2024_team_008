require 'rails_helper'

RSpec.describe Server, type: :model do
  let!(:mystery_box) { create(:item, item_name: "Mystery Box", item_type: "box", item_attributes: {}) }
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
end