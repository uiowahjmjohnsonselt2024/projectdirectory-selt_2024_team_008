FactoryBot.define do
  factory :message do
    content { "Hello, World!" }
    association :user
    association :server
  end
end