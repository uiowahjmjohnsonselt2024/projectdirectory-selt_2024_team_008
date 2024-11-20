require 'rails_helper'

RSpec.describe ServersController, type: :request do
  let(:user) { create(:user) }
  let(:server) { create(:server, creator: user) }
  let(:valid_params) { { server: { name: "Test Server" } } }
  let(:invalid_params) { { server: { name: "" } } }

  before do
    sign_in user
  end

  describe "GET /servers" do
    it "lists all servers the user has joined" do
      Membership.find_or_create_by(user: user, server: server)
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
        Membership.find_or_create_by(user: user, server: server)
      end

      it "shows the server details" do
        get server_path(server)
        expect(response).to have_http_status(:ok)
        expect(assigns(:server)).to eq(server)
        expect(assigns(:messages)).to eq(server.messages)
      end
    end

    context "when the user is not a member" do
      it "adds the user to the server's membership and logs the action" do
        allow(Rails.logger).to receive(:info) 

        # Create a server with a different creator
        another_user = create(:user)
        server = create(:server, creator: another_user)

        # Ensure the test user is not already a member
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
        allow_any_instance_of(Server).to receive(:memberships).and_raise(StandardError, "Membership creation failed")
        allow(Rails.logger).to receive(:error)
      end

      it "logs the error and still proceeds to show the server" do
        allow_any_instance_of(Server).to receive(:memberships).and_raise(StandardError, "Membership creation failed")
        allow(Rails.logger).to receive(:error)

        get server_path(server)

        expect(response).to have_http_status(:ok)
        expect(Rails.logger).to have_received(:error).with(/Membership creation failed/).at_least(:once)
      end
    end
  end
end
