FactoryBot.define do
  factory :game do
    name { "Test Game" }
    creator { association(:user) }
    game_status { "waiting" }

    after(:build) do |game|
      # Build the server associated with the game
      game.server = build(:server, creator: game.creator, game: game) unless game.server
    end
  end
end