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
              { item_name: "Mystery Box", item_type: "Box", item_attributes: { rarity: "Special", description: "A box containing random items." } },
              { item_name: "Sword of Legends", item_type: "Weapon", item_attributes: { rarity: "Legendary", damage: 100, description: "A powerful weapon from the old times." } },
              { item_name: "Potion of Healing", item_type: "Potion", item_attributes: { rarity: "Common", healing: 50, description: "A potion that restores health." } },
              { item_name: "Shield of Aegis", item_type: "Armor", item_attributes: { rarity: "Rare", defense: 75, description: "A shield that blocks powerful attacks." } },
              { item_name: "Scroll of Fireball", item_type: "Scroll", item_attributes: { rarity: "Uncommon", magic: 200, description: "A spell that causes fiery destruction." } }
            ])