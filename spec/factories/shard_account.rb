# factories/shard_accounts.rb
FactoryBot.define do
  factory :shard_account do
    balance { 100 }
    user
  end
end