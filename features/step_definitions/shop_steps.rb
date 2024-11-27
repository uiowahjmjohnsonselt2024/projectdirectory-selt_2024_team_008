When(/^I am on the shop page$/) do
  visit shop_index_path
end

Then("I should be redirected to the menu page") do
  expect(current_path).to eq(root_path) # Replace with the actual route helper for the menu
end

Then("I should be redirected to the buy shards page") do
  expect(current_path).to eq(buy_shards_shard_accounts_path)
end

Then("I should be redirected to the mystery boxes page") do
  expect(current_path).to eq(open_mystery_boxes_path)
end