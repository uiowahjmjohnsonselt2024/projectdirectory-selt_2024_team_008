class CreateItems < ActiveRecord::Migration[7.0]
  def change
    create_table :items do |t|
      t.string :item_name, null: false
      t.string :item_type, null: false
      t.json :attributes
      t.timestamps
    end
  end
end
