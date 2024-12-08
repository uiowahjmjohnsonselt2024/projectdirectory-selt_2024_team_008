class AddForeignKeysWithCascadeAndNullify < ActiveRecord::Migration[7.0]
  def change
    # Foreign key for games -> servers
    add_foreign_key "games", "servers", on_delete: :cascade

    # Foreign key for games -> users
    add_foreign_key "games", "users", column: "creator_id", on_delete: :nullify

    # Foreign key for memberships -> servers
    add_foreign_key "memberships", "servers", on_delete: :cascade

    # Foreign key for memberships -> games
    add_foreign_key "memberships", "games", on_delete: :cascade

    # Foreign key for memberships -> users
    add_foreign_key "memberships", "users", on_delete: :nullify

    # Foreign key for messages -> servers
    add_foreign_key "messages", "servers", on_delete: :cascade

    # Foreign key for messages -> users
    add_foreign_key "messages", "users", on_delete: :nullify

    # Foreign key for servers -> games
    add_foreign_key "servers", "games", on_delete: :cascade

    # Foreign key for servers -> users
    add_foreign_key "servers", "users", column: "creator_id", on_delete: :nullify
  end
end