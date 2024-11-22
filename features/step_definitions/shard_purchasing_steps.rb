# features/step_definitions/shard_purchasing_steps.rb

Given("I am on the shard purchasing page") do
  visit buy_shards_shard_accounts_path # Replace `shard_purchasing_path` with your actual route helper
end

Given("I am logged in as a user with a shard balance of {int} shards") do |shard_balance|
  @user = User.create!(username: "test", email: "test@example.com", password: "password")
  @user.shard_account.balance = shard_balance
  login_as(@user, scope: :user) # Use Devise's login_as helper or adjust based on your authentication system
end

Then("I should see a button with text {string}") do |button_text|
  expect(page).to have_button(button_text)
end

# Then("I should see {string}") do |text|
#   expect(page).to have_content(text)
# end

Then("I should see a currency dropdown with options {string}") do |options|
  dropdown_options = options.split(", ").map(&:strip)
  dropdown_options.each do |option|
    expect(page).to have_select("currency", with_options: [option])
  end
end

When("I click the {string} button") do |button_text|
  click_button(button_text)
end

When("I enter {string} into the {string} field") do |value, field_label|
  fill_in(field_label, with: value)
end

When("I select {string} from the {string} dropdown") do |option, dropdown_label|
  select(option, from: dropdown_label)
end

Then("I should be redirected to the shop page") do
  expect(current_path).to eq(shop_index_path) # Replace `shop_index_path` with your actual route helper
end

Then("I should see a conversion result displayed") do
  expect(page).to have_css("#conversion-result")
end

Then("I should see an error message saying {string}") do |error_message|
  expect(page).to have_content(error_message)
end

Then("I should see a confirmation message saying {string}") do |confirmation_message|
  expect(page).to have_content(confirmation_message)
end

Then("my shard balance should be updated to {string}") do |new_balance|
  shard_balance_text = find(".shard-balance-display p").text
  expect(shard_balance_text).to include(new_balance)
end


Then("I should see a popup message saying {string}") do |message|
  expect(page.driver.browser.alert_messages.last).to eq(message)
end

When("I accept the popup message") do
  page.driver.browser.accept_js_confirms
end

