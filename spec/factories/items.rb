FactoryBot.define do
  factory :item do
    item_name { "Default Item" }
    item_type { "default_type" }
    item_attributes { {} }
  end
end