class CreateUserItems < ActiveRecord::Migration[7.0]
  def change
    create_table :user_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :quantity, default: 0, null: false
      t.timestamps
    end
  end
end
