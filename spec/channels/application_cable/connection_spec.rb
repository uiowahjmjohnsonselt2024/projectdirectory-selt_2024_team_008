require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  let!(:mystery_box) { create(:item, item_name: "Mystery Box", item_type: "box", item_attributes: {}) }
  let(:user) { create(:user) }

  context "when a valid user_id is in cookies" do
    before do
      allow_any_instance_of(ApplicationCable::Connection).to receive(:env).and_return('warden' => instance_double(Warden::Proxy, user: user))
    end

    it "successfully connects and sets current_user" do
      # Simulate the signed cookie with the user's ID
      cookies.signed[:user_id] = user.id

      connect "/cable"

      # Ensure the connection is successful and current_user is set
      expect(connection.current_user).to eq(user)
    end
  end

  context "when no valid user_id is in cookies" do
    before do
      allow_any_instance_of(ApplicationCable::Connection).to receive(:env).and_return('warden' => instance_double(Warden::Proxy, user: nil))
    end

    it "rejects the connection" do
      # Ensure no valid cookie is set
      cookies.signed[:user_id] = nil

      expect {
        connect "/cable"
      }.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
    end
  end

  context "when the user_id in cookies does not match a user" do
    before do
      allow_any_instance_of(ApplicationCable::Connection).to receive(:env).and_return('warden' => instance_double(Warden::Proxy, user: nil))
    end

    it "rejects the connection" do
      # Set an invalid user ID
      cookies.signed[:user_id] = 99999 # ID that doesn't exist in the database

      expect {
        connect "/cable"
      }.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
    end
  end
end