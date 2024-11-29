class UpdateServerKey < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :servers, :users, on_delete: :cascade
    add_foreign_key :servers, :users, column: :creator_id, on_delete: :nullify
  end
end
