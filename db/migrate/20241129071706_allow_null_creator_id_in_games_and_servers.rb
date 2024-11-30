class AllowNullCreatorIdInGamesAndServers < ActiveRecord::Migration[7.0]
  def change
    change_column_null :games, :creator_id, true
    change_column_null :servers, :creator_id, true
  end
end
