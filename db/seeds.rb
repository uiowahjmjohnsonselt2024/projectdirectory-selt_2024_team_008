# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

ShopItem.create([
                  { name: "Sword of Valor", description: "A legendary weapon.", price_in_shards: 100 },
                  { name: "Healing Potion", description: "Restores 50 health points.", price_in_shards: 5 }
                ])