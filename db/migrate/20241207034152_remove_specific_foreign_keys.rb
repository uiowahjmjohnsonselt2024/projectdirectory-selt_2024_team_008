class RemoveSpecificForeignKeys < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key "memberships", "servers" if foreign_key_exists?("memberships", "servers")
    remove_foreign_key "messages", "servers" if foreign_key_exists?("messages", "servers")
    remove_foreign_key "servers", "users", column: "creator_id" if foreign_key_exists?("servers", "users", column: "creator_id")
  end
end