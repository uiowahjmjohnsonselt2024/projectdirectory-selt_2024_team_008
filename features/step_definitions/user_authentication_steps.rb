
Given('a user with email {string} and password {string} exists') do |email, password|
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

