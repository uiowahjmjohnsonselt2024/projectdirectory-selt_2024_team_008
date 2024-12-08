require 'rails_helper'

RSpec.describe Membership, type: :model do
  let(:user) { User.create!(email: "test@example.com", username: "testuser", password: "password") }
  let(:server) { Server.create!(name: "Test Server", creator_id: user.id) }
  let(:game) { Game.create!(name: "Test Game", creator_id: user.id, server_id: server.id) }

  describe "#log_membership_creation" do
    context "when server_id and game_id are present" do
      it "logs a membership creation event" do
        # Explicitly create a membership to test logging
        new_user = User.create!(email: "new@example.com", username: "newuser", password: "password")
        membership = Membership.new(user: new_user, server: server, game: game)

        # Expect logger to log the membership creation
        expect(Rails.logger).to receive(:info).with(
          "Membership created: User #{new_user.id} joined Game #{game.id}, Server #{server.id}"
        )

        # Save the membership to trigger the after_create callback
        membership.save!
      end
    end
  end
end
