class CreateShopItems < ActiveRecord::Migration[7.0]
  def change
    create_table :shop_items do |t|
      t.string :name
      t.text :description
      t.integer :price_in_shards

      t.timestamps
    end
  end
end
