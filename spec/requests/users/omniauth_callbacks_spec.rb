require 'rails_helper'

RSpec.describe "Users::OmniauthCallbacks", type: :request do
  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
                                                                         provider: 'google_oauth2',
                                                                         uid: '1234567890',
                                                                         info: {
                                                                           email: 'testuser@example.com',
                                                                           name: 'Test User'
                                                                         }
                                                                       })
  end

  describe "GET /users/auth/google_oauth2/callback" do
    context "when user is new" do
      it "creates a new user and redirects to the dashboard" do
        expect {
          get user_google_oauth2_omniauth_callback_path
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(main_menu_path)
      end
    end

    context "when user already exists" do
      let!(:existing_user) { User.create!(email: 'testuser@example.com', provider: 'google_oauth2', uid: '1234567890', password: 'password', username: 'TestUser') }

      it "does not create a new user and signs in the existing user" do
        expect {
          get user_google_oauth2_omniauth_callback_path
        }.not_to change(User, :count)

        expect(response).to redirect_to(main_menu_path)
      end
    end

    context "when OmniAuth fails" do
      before do
        OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
      end

      it "redirects to the sign-in page with an error message" do
        get user_google_oauth2_omniauth_callback_path

        expect(response).to redirect_to(new_user_session_path)
        follow_redirect!
        expect(response.body).to include("Something went wrong. Please try again.")
      end
    end
  end
end
