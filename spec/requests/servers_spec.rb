require 'rails_helper'

RSpec.describe ServersController, type: :request do
  let!(:mystery_box) { create(:item, item_name: "Mystery Box", item_type: "box", item_attributes: {}) }
  let(:user) { create(:user) }
  let(:server) { create(:server, creator: user) }
  let(:valid_params) { { server: { name: "Test Server" } } }
  let(:invalid_params) { { server: { name: "" } } }

  before(:each) do
    sign_in user
    Membership.destroy_all
    Server.destroy_all
  end

  describe "GET /servers" do
    it "lists all servers the user has joined" do
      Membership.find_or_create_by!(user: user, server: server)
      get servers_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /servers" do
    context "with valid parameters" do
      it "creates a new server and redirects to it" do
        expect {
          post servers_path, params: valid_params
        }.to change(Server, :count).by(1)
        expect(response).to redirect_to(server_path(Server.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new server and re-renders the form" do
        expect {
          post servers_path, params: invalid_params
        }.not_to change(Server, :count)

        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /servers/:id" do
    context "when the user is a member" do
      before do
        Membership.find_or_create_by!(user: user, server: server)
      end

      it "shows the server details" do
        get server_path(server)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(server.name)
      end
    end

    context "when the user is not a member" do
      it "adds the user to the server's membership and logs the action" do
        allow(Rails.logger).to receive(:info)

        another_user = create(:user)
        server = create(:server, creator: another_user)

        expect(server.memberships.exists?(user_id: user.id)).to be_falsey

        expect {
          get server_path(server)
        }.to change(Membership, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(Rails.logger).to have_received(:info).with("Added user #{user.id} to server #{server.id}").at_least(:once)
      end
    end

    context "when an error occurs while adding the user to the server" do
      before do
        # Allow any error to be logged
        allow(Rails.logger).to receive(:error)

        # Stub `create!` to raise the error
        allow_any_instance_of(ActiveRecord::Associations::CollectionProxy)
          .to receive(:create!).and_raise(StandardError, "Membership creation failed")
      end

      it "logs the error and still proceeds to show the server" do
        get server_path(server)

        # Ensure the response is still OK
        expect(response).to have_http_status(:ok)

        # Verify the error message was logged
        expect(Rails.logger).to have_received(:error).with(/Membership creation failed/).at_least(:once)
      end
    end
  end

  describe "POST /servers/:id/update_status" do
    context "when the server exists and user is authenticated" do
      before do
        Membership.find_or_create_by!(user: user, server: server)
      end

      it "updates the status to 'online' and broadcasts the status update" do
        expect(ActionCable.server).to receive(:broadcast).with(
          "server_#{server.id}_users",
          hash_including(user_id: user.id, status: 'online')
        )

        post update_status_server_path(server), params: { status: 'online' }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq("Status updated to online")
        expect(user.reload.last_seen_at).not_to be_nil
      end

      it "updates the status to 'offline' and clears the last_seen_at" do
        user.update!(last_seen_at: Time.current)

        expect(ActionCable.server).to receive(:broadcast).with(
          "server_#{server.id}_users",
          hash_including(user_id: user.id, status: 'offline')
        )

        post update_status_server_path(server), params: { status: 'offline' }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq("Status updated to offline")
        expect(user.reload.last_seen_at).to be_nil
      end
    end

    context "when the server does not exist" do
      it "returns a not found error" do
        post update_status_server_path(id: 0), params: { status: 'online' }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Server not found')
      end
    end

    context "when the user is not authenticated" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(false)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      end

      it "returns an unauthorized error" do
        post update_status_server_path(server), params: { status: 'online' }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('User not authenticated')
      end
    end
  end

end