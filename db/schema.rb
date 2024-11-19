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

ActiveRecord::Schema[7.0].define(version: 2024_11_18_040343) do
  enable_extension "plpgsql"

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
    t.index "LOWER(username)", name: "index_users_on_lower_username", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end
  
  create_table "memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "server_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["server_id"], name: "index_memberships_on_server_id"
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
    t.integer "creator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_servers_on_creator_id"
  end

  add_foreign_key "memberships", "servers"
  add_foreign_key "memberships", "users"
  add_foreign_key "messages", "servers"
  add_foreign_key "messages", "users"
  add_foreign_key "servers", "users", column: "creator_id"
  add_foreign_key "shard_accounts", "users"
end
