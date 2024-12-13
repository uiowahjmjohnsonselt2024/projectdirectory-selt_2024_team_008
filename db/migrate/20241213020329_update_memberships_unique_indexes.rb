class UpdateMembershipsUniqueIndexes < ActiveRecord::Migration[7.0]
  def change
    # Check and remove the existing conflicting unique index
    if index_name_exists?(:memberships, "index_memberships_on_user_id_and_server_id")
      remove_index :memberships, name: "index_memberships_on_user_id_and_server_id"
    end

    # Add a new unique index for [:user_id, :server_id, :game_id]
    unless index_name_exists?(:memberships, "index_memberships_on_user_server_game")
      add_index :memberships, [:user_id, :server_id, :game_id], unique: true, name: "index_memberships_on_user_server_game"
    end
  end
end