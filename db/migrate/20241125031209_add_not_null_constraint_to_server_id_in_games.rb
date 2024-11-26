class AddNotNullConstraintToServerIdInGames < ActiveRecord::Migration[7.0]
  def change
    change_column_null :games, :server_id, false
  end
end