# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


# NOTE: Will probably want to remove this later, using it for dev

Server.all.each do |server|
  User.all.each do |user|
    Membership.find_or_create_by(user: user, server: server)
  end
end

