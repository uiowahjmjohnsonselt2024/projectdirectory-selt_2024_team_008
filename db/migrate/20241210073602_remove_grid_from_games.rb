class RemoveGridFromGames < ActiveRecord::Migration[7.0]
  def change
    if column_exists?(:games, :grid)
      remove_column :games, :grid
    else
      puts "Column 'grid' does not exist in 'games' table. Skipping migration."
    end
  end
end