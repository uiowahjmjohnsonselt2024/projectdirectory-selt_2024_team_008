FactoryBot.define do
  factory :server do
    sequence(:name) { |n| "Server #{n}" }
    association :creator, factory: :user
  end
end