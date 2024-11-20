FactoryBot.define do
  factory :membership do
    association :user
    association :server
  end
end