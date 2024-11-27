require 'rails_helper'

RSpec.describe "ServersController", type: :request do
  let(:user) { create(:user) }
  let(:server) { create(:server, creator: user) }
  let(:valid_params) { { server: { name: "Test Server" } } }
  let(:invalid_params) { { server: { name: "" } } }

  before do
    sign_in user
  end

  def json_response
    JSON.parse(response.body)
  end

  describe "GET /servers" do
    before { Membership.find_or_create_by!(user: user, server: server) }

    it "renders servers list in HTML" do
      get servers_path, headers: { "ACCEPT" => "text/html" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Servers list: #{server.name}")
    end

    it "renders servers list in JSON" do
      get servers_path, headers: { "ACCEPT" => "application/json" }
      expect(response).to have_http_status(:ok)
      expect(json_response).to include({ "id" => server.id, "name" => server.name }.stringify_keys)
    end
  end

  describe "POST /servers" do
    context "with valid parameters" do
      it "creates a new server and redirects" do
        expect { post servers_path, params: valid_params }.to change(Server, :count).by(1)
        expect(response).to redirect_to(server_path(Server.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a server and re-renders form" do
        expect { post servers_path, params: invalid_params }.not_to change(Server, :count)
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /servers/:id" do
    it "renders server details" do
      Membership.find_or_create_by!(user: user, server: server)
      get server_path(server)
      expect(response).to have_http_status(:ok)
    end

    it "returns error if server is not found" do
      get server_path(id: 999)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /servers/:id/ensure_membership" do
    it "ensures membership if user is not a member" do
      new_server = create(:server, creator: create(:user)) # Different creator user
      expect { post ensure_membership_server_path(new_server) }.to change(Membership, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(json_response["message"]).to eq("Membership ensured")
      expect(new_server.memberships.exists?(user: user)).to be_truthy
    end

    it "returns error if server is not found" do
      post ensure_membership_server_path(id: 999)
      expect(response).to have_http_status(:not_found)
      expect(json_response["error"]).to eq("Server not found")
    end

    it "returns error if unable to create membership" do
      # Mock save failure and populate errors for Membership
      allow_any_instance_of(Membership).to receive(:save).and_return(false)
      allow_any_instance_of(Membership).to receive(:errors).and_return(double(full_messages: ["Test error"]))

      # Mock the `memberships` association on Server
      allow_any_instance_of(Server).to receive(:add_creator_to_memberships).and_return(nil)

      post ensure_membership_server_path(server)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["error"]).to include("Unable to create membership: Test error")
    end

    it "returns a success message if membership already exists" do
      # Ensure the user is already a member
      Membership.find_or_create_by!(user: user, server: server)

      # Make the request
      post ensure_membership_server_path(server)

      # Assertions
      expect(response).to have_http_status(:ok)
      expect(json_response["message"]).to eq("Membership already exists")
    end
  end

  describe "POST /servers/:id/update_status" do
    context "authenticated user" do
      it "updates status to online and broadcasts" do
        expect(ActionCable.server).to receive(:broadcast).with(
          "server_#{server.id}",
          hash_including(type: 'status', user_id: user.id, status: 'online')
        )
        post update_status_server_path(server), params: { status: "online" }
        expect(response).to have_http_status(:ok)
        expect(json_response["message"]).to eq("Status updated to online")
      end

      it "returns error for invalid status" do
        post update_status_server_path(server), params: { status: "busy" }
        expect(response).to have_http_status(:bad_request)
        expect(json_response["error"]).to eq("Invalid status")
      end
    end

    context "unauthenticated user" do
      before { sign_out user }

      it "returns unauthorized error" do
        post update_status_server_path(server), params: { status: "online" }, headers: { "ACCEPT" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
        expect(json_response["error"]).to eq("You need to sign in or sign up before continuing.")
      end
    end
  end
end