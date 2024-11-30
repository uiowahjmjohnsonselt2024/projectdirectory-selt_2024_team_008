FactoryBot.define do
  factory :game do
    name { "Test Game" }
    association :creator, factory: :user # Assumes a user factory exists
    status { :waiting } # Default status, mapped via the enum
    grid { Array.new(6) { Array.new(6, nil) } } # Default grid structure
    association :server

    trait :waiting do
      status { :waiting }
    end

    trait :in_progress do
      status { :in_progress }
    end

    trait :completed do
      status { :completed }
    end
  end
end