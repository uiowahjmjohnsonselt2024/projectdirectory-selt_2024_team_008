class A < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :servers, :users, column: :creator_id, on_delete: :cascade
  end
end
