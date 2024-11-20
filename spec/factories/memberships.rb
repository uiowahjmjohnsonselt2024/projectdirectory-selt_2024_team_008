FactoryBot.define do
  factory :membership do
    association :user
    association :server

    after(:build) do |membership|
      Membership.find_or_create_by!(user: membership.user, server: membership.server)
    end
  end
end
