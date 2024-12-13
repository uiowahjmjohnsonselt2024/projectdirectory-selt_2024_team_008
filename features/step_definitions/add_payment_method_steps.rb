Given("I am logged in as a user with a shard account") do
  @user = User.create(email: 'user@example.com', password: 'password')
  @user.shard_account = ShardAccount.create(balance: 50)
  @user.save
  login_as(@user)  # Use Devise's login_as helper if using Devise for authentication
end

Given("I am on the \"Add a Card to Your Shard Account\" page") do
  visit new_shard_account_card_path(@user.shard_account)
end

Then("I should see the heading {string}") do |heading|
  expect(page).to have_content(heading)
end

When("I fill the card field {string} with {string}") do |field, value|
  case field
  when "Card Number"
    fill_in "card_number_encrypted", with: value
  when "Expiry Date (MM/YY)"
    fill_in "expiry_date", with: value
  when "CVV"
    fill_in "cvv_encrypted", with: value
  when "Street Address"
    fill_in "billing_address", with: value
  else
    raise "Unknown field: #{field}"
  end
end



Then("I should see a \"Save Information\" button") do
  expect(page).to have_button("Save Information")
end

When("I click the {string} button") do |button|
  click_button button
end

Then("I should see a confirmation message saying {string}") do |message|
  expect(page).to have_content(message)
end

Then("I should see the following error messages:") do |table|
  table.hashes.each do |row|
    expect(page).to have_content("#{row['Card Number']} #{row['Value']}")
  end
end
