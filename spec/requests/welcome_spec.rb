require 'rails_helper'
#uses welcome_path in one test and root_path in the other because they should lead to the same page
RSpec.describe "Welcome Page", type: :request do
  it "shows welcome screen" do
    get welcome_path
    expect(response.body).to include('Shards of the Grid')
  end

  it "User sees the 'Login' button" do
    get root_path

    expect(response.body).to include('<form class="button_to" method="get" action="/users/sign_in"><input class="button" type="submit" value="Login" /></form>')
  end
end