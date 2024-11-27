#sessions_spec will be used to test the log in page with rspec tests
require 'rails_helper'

RSpec.describe "User Login", type: :request do
  let!(:mystery_box) { create(:item, item_name: "Mystery Box", item_type: "box", item_attributes: {}) }

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

  it "does not log in with invalid password" do
    post user_session_path, params: {
      user: {
        login: "test@example.com",
        password: "wrongpassword"
      }
    }

    expect(response.body).to include("Invalid Login or password")
  end

  it "does not log in with invalid login field" do
    post user_session_path, params: {
      user: {
        login: "wronglogin@example.com",
        password: "password"
      }
    }

    expect(response.body).to include("Invalid Login or password")
  end

  it "does not log in with a blank password field" do
    post user_session_path, params: {
      user: {
        login: "test@example.com",
        password: ""
      }
    }
  end

  it 'redirects to the correct path after a successful login' do
    post user_session_path, params: {
      user: {
        login: "test@example.com",
        password: "password"
      }
    }
    expect(response).to redirect_to(root_path)
  end

  it 'logs out successfully and redirects user to login page' do
    post user_session_path, params: {
      user: {
        login: "test@example.com",
        password: "password"
      }
    }
    follow_redirect!
    delete destroy_user_session_path
    expect(response).to redirect_to(root_path) #THIS MIGHT NEED TO CHANGE LATER
  end


end

