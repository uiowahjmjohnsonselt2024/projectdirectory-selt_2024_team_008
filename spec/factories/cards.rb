# factories/cards.rb
FactoryBot.define do
  factory :card do
    card_number_encrypted { "1234567812345678" }
    expiry_date { "12/25" }
    cvv_encrypted { "123" }
    billing_address { "100 main st" }
    association :shard_account
  end
end