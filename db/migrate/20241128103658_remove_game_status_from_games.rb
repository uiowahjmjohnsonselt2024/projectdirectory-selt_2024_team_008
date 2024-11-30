class RemoveGameStatusFromGames < ActiveRecord::Migration[7.0]
  def change
    remove_column :games, :game_status, :string
  end
end
