class FixFKeys < ActiveRecord::Migration[7.0]
  def change
    # Drop and recreate memberships foreign keys
    remove_foreign_key :memberships, :servers
    add_foreign_key :memberships, :servers, on_delete: :cascade

    remove_foreign_key :memberships, :users
    add_foreign_key :memberships, :users, on_delete: :cascade

    # Fix games foreign key
    remove_foreign_key :games, :servers
    add_foreign_key :games, :servers, on_delete: :cascade

    # Fix messages foreign keys
    remove_foreign_key :messages, :servers
    add_foreign_key :messages, :servers, on_delete: :cascade

    remove_foreign_key :messages, :users
    add_foreign_key :messages, :users, on_delete: :cascade

    # Fix servers foreign key
    remove_foreign_key :servers, :users
    add_foreign_key :servers, :users, column: "creator_id", on_delete: :cascade
  end
end