
Given('a user with email {string} and password {string} exists') do |email, password|
  Item.find_or_create_by!(item_name: "Mystery Box", item_type: "box", item_attributes: {})
  User.create!(email: email, password: password, username: 'testuser')
end

When("I go to the login page") do
  visit new_user_session_path
end

When("I fill in {string} with {string}") do |field, value|
  fill_in field, with: value
end

When("I press {string}") do |button|
  click_button button
end

Given("I am logged in as {string} with password {string}") do |email, password|
  visit new_user_session_path
  fill_in "Email or Username", with: email
  fill_in "Password", with: password
  click_button "Log in"
end

When("I click {string}") do |link|
  click_link link
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

# Step for configuring OmniAuth for Google with default successful credentials
Given("OmniAuth is configured for Google") do
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

# Step for configuring OmniAuth with invalid credentials
Given("OmniAuth is configured with invalid credentials for Google") do
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
end

# Step for configuring OmniAuth with a specific email
Given("OmniAuth is configured for Google with email {string}") do |email|
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
                                                                       provider: 'google_oauth2',
                                                                       uid: '1234567890',
                                                                       info: {
                                                                         email: email,
                                                                         name: 'Test User'
                                                                       }
                                                                     })
end

# Step for navigating to the login page
Given("I visit the login page") do
  visit new_user_session_path
end

# Step for verifying redirection to the dashboard
Then("I should be redirected to the dashboard") do
  expect(page).to have_current_path('/main_menu')
end

# Step for verifying redirection to the login page
Then("I should be redirected to the login page") do
  expect(page).to have_current_path(new_user_session_path)
end

# Step for being on new user registration page
And(/^I should be redirected to the sign up page$/) do
  expect(page).to have_current_path('/users/sign_up')
end