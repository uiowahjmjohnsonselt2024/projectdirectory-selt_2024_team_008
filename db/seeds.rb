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

Item.create([
              { item_name: "Mystery Box", item_type: "Box", images: "mysteryBox.png", item_attributes: { rarity: "Special", description: "A box containing random items." } },
              { item_name: "Red Hat", item_type: "Cosmetic", images: "redHat.png", item_attributes: { rarity: "Rare", description: "It's red" } },
              { item_name: "Gold Boots", item_type: "Cosmetic", images: "goldBoots.png", item_attributes: { rarity: "Rare", description: "They're Gold" } },
              { item_name: "Fancy Gloves", item_type: "Cosmetic", images: "fancyGloves.png", item_attributes: { rarity: "Rare", description: "Very Fancy gloves" } },
              { item_name: "Hawaiian Shirt", item_type: "Cosmetic", images: "hawaiianShirt.png", item_attributes: { rarity: "Rare", description: "Very Hawaiian Shirt" } },
              { item_name: "Jean Shorts", item_type: "Cosmetic", images: "jeanShorts.png", item_attributes: { rarity: "Rare", description: "Like jeans but shorter" } }
            ])