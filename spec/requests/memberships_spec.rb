require 'rails_helper'

RSpec.describe "MembershipsController", type: :request do
  let(:creator) { create(:user) }
  let(:user) { create(:user) }
  let!(:server) { create(:server, creator: creator) }

  before do
    sign_in user
  end

  describe "POST /servers/:server_id/memberships" do
    context "when the user successfully joins the server" do
      it "creates a new membership and returns a success message" do
        expect {
          post server_memberships_path(server), headers: { "ACCEPT" => "application/json" }
        }.to change(Membership, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq("message" => "You have joined the server.")
      end
    end

    context "when the user is already a member of the server" do
      before do
        Membership.find_or_create_by!(user: user, server: server)
      end

      it "does not create a duplicate membership and returns an error message" do
        expect {
          post server_memberships_path(server), headers: { "ACCEPT" => "application/json" }
        }.not_to change(Membership, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("already a member")
      end
    end

    context "when the server does not exist" do
      it "returns a not found error" do
        expect {
          post server_memberships_path(server_id: 999), headers: { "ACCEPT" => "application/json" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "DELETE /servers/:server_id/memberships/:id" do
    let!(:membership) { Membership.find_or_create_by!(user: user, server: server) }

    context "when the user successfully leaves the server" do
      it "deletes the membership and returns a success message" do
        expect {
          delete server_membership_path(server, membership), headers: { "ACCEPT" => "application/json" }
        }.to change(Membership, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq("message" => "You have left the server.")
      end
    end

    context "when the user is not a member of the server" do
      it "does not delete any membership and returns an error message" do
        # Ensure no memberships exist for the current user and server
        Membership.where(user: user, server: server).destroy_all

        expect {
          delete server_membership_path(server, id: 999), headers: { "ACCEPT" => "application/json" }
        }.not_to change(Membership, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq("error" => "Failed to leave the server.")
      end
    end
  end
end