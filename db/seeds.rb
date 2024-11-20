# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


# NOTE: Will probably want to remove this later, using it for dev

test_user = User.find_or_create_by!(email: 'test_user@example.com') do |user|
  user.username = 'testuser'
  user.password = 'password123' # Ensure this matches your application's requirements
end

test_server = Server.find_or_create_by!(name: 'Test Server', creator: test_user)

Membership.find_or_create_by!(user: test_user, server: test_server)

puts "Seeded test_user with membership to Test Server."