class CreateServers < ActiveRecord::Migration[7.0]
  def change
    create_table :servers do |t|
      t.string :name, null: false
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
