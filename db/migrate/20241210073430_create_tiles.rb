class CreateTiles < ActiveRecord::Migration[7.0]
  def change
    create_table :tiles do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :owner
      t.string :occupant
      t.string :color

      t.timestamps
    end

    add_index :tiles, [:game_id, :x, :y], unique: true
  end
end