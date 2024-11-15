# frozen_string_literal: true

# features/step_definitions/authentication_steps.rb
Given('I am a visitor') do
  # No setup needed for a visitor
end

Given('I am a registered user') do
  @user = FactoryBot.create(:user) # Assumes FactoryBot is set up to create test users
end

Given('I am logged in as a registered user') do
  @user = FactoryBot.create(:user)
  visit new_user_session_path
  fill_in 'Email', with: @user.email
  fill_in 'Password', with: @user.password
  click_button 'Log in'
end

When('I navigate to the login page') do
  visit new_user_session_path
end

When('I submit my email and password') do
  fill_in 'Email', with: @user.email
  fill_in 'Password', with: @user.password
  click_button 'Log in'
end

When('I enter an incorrect password') do
  fill_in 'Email', with: @user.email
  fill_in 'Password', with: 'wrongpassword'
  click_button 'Log in'
end

When('I log out') do
  click_link 'Logout' # TODO: Ensure there's a logout link in the app
end

Then('the login form is displayed') do
  expect(page).to have_selector('form', id: 'new_user') # TODO: Ensure form ID matches our login form
end

Then('I am logged in successfully') do
  expect(page).to have_content('Signed in successfully') # TODO: Adjust based on our actual flash message
end

Then('an error message is displayed') do
  expect(page).to have_content('Invalid Email or password.') # TODO: Adjust based on our actual error message
end

Then('I am redirected to the home page') do
  expect(current_path).to eq(root_path)
end

Then('I remain on the login page') do
  expect(current_path).to eq(new_user_session_path)
end

Then('a logout confirmation message is displayed') do
  expect(page).to have_content('Signed out successfully') # Adjust based on your actual flash message
end
