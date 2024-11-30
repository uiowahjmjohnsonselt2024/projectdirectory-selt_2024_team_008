class AddGridToGames < ActiveRecord::Migration[7.0]
  def change
    add_column :games, :grid, :text
  end
end
