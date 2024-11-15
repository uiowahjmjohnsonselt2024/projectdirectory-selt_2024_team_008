#sessions_spec will be used to test the log in page with rspec tests
require 'rails_helper'

RSpec.describe "User Login", type: :request do
  before do
    User.create(username: "testuser", login: "test@example.com", password: "password", email: "test@example.com")
  end

  it "logs in successfully with valid credentials" do
    post user_session_path, params: {
      user: {
        login: "test@example.com",
        password: "password"
      }
    }
    expect(response).to redirect_to(root_path)  #ROUTE NEEDS TO CHANGE
    follow_redirect!
    expect(response.body).to include("Signed in successfully")
  end

  it "does not log in with invalid credentials" do
    post user_session_path, params: {
      user: {
        login: "test@example.com",
        password: "wrongpassword"
      }
    }

    expect(response.body).to include("Invalid Login or password")
  end
end

