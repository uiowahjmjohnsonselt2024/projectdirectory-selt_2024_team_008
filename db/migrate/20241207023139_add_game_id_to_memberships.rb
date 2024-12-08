class AddGameIdToMemberships < ActiveRecord::Migration[7.0]
  def change
    # Add the column only if it doesn't already exist
    unless column_exists?(:memberships, :game_id)
      add_column :memberships, :game_id, :integer
    end

    # Add an index for game_id only if it doesn't already exist
    unless index_exists?(:memberships, :game_id)
      add_index :memberships, :game_id
    end

    # Add a unique index for [:user_id, :game_id] only if it doesn't already exist
    unless index_exists?(:memberships, [:user_id, :game_id], unique: true)
      add_index :memberships, [:user_id, :game_id], unique: true
    end
  end
end
