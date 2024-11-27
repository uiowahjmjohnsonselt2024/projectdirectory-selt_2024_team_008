FactoryBot.define do
  factory :server do
    sequence(:name) { |n| "Server #{n}" }
    association :creator, factory: :user
    game { nil } # Allow the server to be created without a game initially

    after(:build) do |server|
      if server.game.present? && server.name.blank?
        server.name = "Chat Room for #{server.game.name}"
      end
    end
  end
end