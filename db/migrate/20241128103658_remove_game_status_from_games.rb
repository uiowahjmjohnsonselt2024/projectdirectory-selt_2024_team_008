class RemoveGameStatusFromGames < ActiveRecord::Migration[7.0]
  def change
    if column_exists?(:games, :game_status)
      remove_column :games, :game_status, :string
    else
      puts "Column :game_status does not exist in :games table"
    end
  end
end
