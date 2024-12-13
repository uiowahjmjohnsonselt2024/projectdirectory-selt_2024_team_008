Given("there are multiple users with different balances") do
  # Create multiple users with different balances
  @user1 = FactoryBot.create(:user, shard_account: FactoryBot.create(:shard_account, balance: 150))
  @user2 = FactoryBot.create(:user, shard_account: FactoryBot.create(:shard_account, balance: 200))
  @user3 = FactoryBot.create(:user, shard_account: FactoryBot.create(:shard_account, balance: 100))
  # You can create additional users if needed
end

When("I visit the leaderboard page") do
  visit leaderboard_path  # Make sure you have the correct path for the leaderboard
end

Then("I should see a list of users with their balances") do
  expect(page).to have_content(@user1.username)
  expect(page).to have_content(@user2.username)
  expect(page).to have_content(@user3.username)
  expect(page).to have_content(@user1.shard_account.balance)
  expect(page).to have_content(@user2.shard_account.balance)
  expect(page).to have_content(@user3.shard_account.balance)
end

Then("the users should be sorted by balance in descending order") do
  usernames = all('table tbody tr td:nth-child(2)').map(&:text)
  balances = all('table tbody tr td:nth-child(3)').map(&:text)

  # Check if the users are ordered by balance (descending order)
  expect(balances).to eq(balances.sort.reverse)
  expect(usernames).to eq(usernames.sort_by { |username| -@user1.shard_account.balance })
end

Given("there are more than 10 users") do
  9.times do |i|
    FactoryBot.create(:user, shard_account: FactoryBot.create(:shard_account, balance: 50))
  end
end

Then("I should see no more than 10 users listed on the page") do
  expect(page).to have_css('table tbody tr', count: 10)
end