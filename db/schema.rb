# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.


ActiveRecord::Schema[7.0].define(version: 2024_12_09_161110) do
  create_table "avatars", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "hat_id"
    t.integer "top_id"
    t.integer "bottoms_id"
    t.integer "shoes_id"
    t.integer "accessories_id"
    t.binary "avatar_image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["accessories_id"], name: "index_avatars_on_accessories_id"
    t.index ["bottoms_id"], name: "index_avatars_on_bottoms_id"
    t.index ["hat_id"], name: "index_avatars_on_hat_id"
    t.index ["shoes_id"], name: "index_avatars_on_shoes_id"
    t.index ["top_id"], name: "index_avatars_on_top_id"
    t.index ["user_id"], name: "index_avatars_on_user_id"

  create_table "cards", force: :cascade do |t|
    t.integer "shard_account_id", null: false
    t.string "card_number_encrypted"
    t.string "expiry_date"
    t.string "cvv_encrypted"
    t.text "billing_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shard_account_id"], name: "index_cards_on_shard_account_id"
  end

  create_table "games", force: :cascade do |t|
    t.string "name", null: false
    t.integer "creator_id"
    t.integer "status", default: 0, null: false
    t.string "external_server_url"
    t.integer "server_id", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "grid"
    t.json "user_colors", default: {}
    t.index ["creator_id"], name: "index_games_on_creator_id"
    t.index ["server_id"], name: "index_games_on_server_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "item_name", null: false
    t.string "item_type", null: false
    t.json "item_attributes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "images"
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "server_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "game_id"
    t.index ["game_id"], name: "index_memberships_on_game_id"
    t.index ["server_id"], name: "index_memberships_on_server_id"
    t.index ["user_id", "game_id"], name: "index_memberships_on_user_id_and_game_id", unique: true
    t.index ["user_id", "server_id"], name: "index_memberships_on_user_id_and_server_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content", null: false
    t.integer "user_id", null: false
    t.integer "server_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["server_id"], name: "index_messages_on_server_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "servers", force: :cascade do |t|
    t.string "name", null: false
    t.integer "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "game_id"
    t.string "original_creator_username"
    t.string "original_creator_email"
    t.integer "original_creator_id"
    t.index ["creator_id"], name: "index_servers_on_creator_id"
    t.index ["game_id"], name: "index_servers_on_game_id"
  end

  create_table "shard_accounts", force: :cascade do |t|
    t.integer "user_id"
    t.integer "balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_shard_accounts_on_user_id"
  end

  create_table "shop_items", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "price_in_shards"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_items", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "item_id", null: false
    t.integer "quantity", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_user_items_on_item_id"
    t.index ["user_id"], name: "index_user_items_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.datetime "last_seen_at"
    t.string "role", default: "user"
    t.string "provider"
    t.string "uid"
    t.index "LOWER(username)", name: "index_users_on_lower_username", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "avatars", "items", column: "accessories_id"
  add_foreign_key "avatars", "items", column: "bottoms_id"
  add_foreign_key "avatars", "items", column: "hat_id"
  add_foreign_key "avatars", "items", column: "shoes_id"
  add_foreign_key "avatars", "items", column: "top_id"
  add_foreign_key "avatars", "users"
  add_foreign_key "games", "servers", on_delete: :cascade
  add_foreign_key "games", "users", column: "creator_id", on_delete: :nullify
  add_foreign_key "memberships", "games", on_delete: :cascade
  add_foreign_key "memberships", "servers", on_delete: :cascade
  add_foreign_key "memberships", "users", on_delete: :nullify
  add_foreign_key "messages", "servers", on_delete: :cascade
  add_foreign_key "messages", "users", on_delete: :nullify
  add_foreign_key "servers", "games", on_delete: :cascade
  add_foreign_key "cards", "shard_accounts"
  add_foreign_key "servers", "users", column: "creator_id", on_delete: :nullify
  add_foreign_key "shard_accounts", "users"
  add_foreign_key "user_items", "items"
  add_foreign_key "user_items", "users"
end
