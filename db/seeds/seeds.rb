# frozen_string_literal: true



# Ensure tables exist before seeding
if ActiveRecord::Base.connection.table_exists?('users') &&
  ActiveRecord::Base.connection.table_exists?('servers') &&
  ActiveRecord::Base.connection.table_exists?('memberships')

  puts "Running seeds in #{Rails.env} environment"

  # Seed data shared between development and test environments
  test_user = User.find_or_create_by!(email: 'test_user@example.com') do |user|
    user.username = 'testuser'
    user.password = 'password' # Ensure this matches your application's requirements
  end

  test_server = Server.find_or_create_by!(name: 'Test Server', creator: test_user)

  Membership.find_or_create_by!(user: test_user, server: test_server)

  puts "Seeded test_user with membership to Test Server in #{Rails.env} environment."
else
  puts "Skipping seeds as required tables do not exist."
end
