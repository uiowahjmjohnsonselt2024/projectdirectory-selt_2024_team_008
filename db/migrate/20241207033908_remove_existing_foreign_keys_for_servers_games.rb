class RemoveExistingForeignKeysForServersGames < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key "games", "servers" if foreign_key_exists?("games", "servers")
    remove_foreign_key "games", "users", column: "creator_id" if foreign_key_exists?("games", "users", column: "creator_id")
    remove_foreign_key "memberships", "servers" if foreign_key_exists?("memberships", "servers")
    remove_foreign_key "memberships", "games" if foreign_key_exists?("memberships", "games")
    remove_foreign_key "memberships", "users" if foreign_key_exists?("memberships", "users")
    remove_foreign_key "messages", "servers" if foreign_key_exists?("messages", "servers")
    remove_foreign_key "messages", "users" if foreign_key_exists?("messages", "users")
    remove_foreign_key "servers", "games" if foreign_key_exists?("servers", "games")
    remove_foreign_key "servers", "users", column: "creator_id" if foreign_key_exists?("servers", "users", column: "creator_id")
  end
end
