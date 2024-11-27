FactoryBot.define do
  factory :game do
    sequence(:name) { |n| "Game #{n}" }
    game_status { "active" }
  end
end