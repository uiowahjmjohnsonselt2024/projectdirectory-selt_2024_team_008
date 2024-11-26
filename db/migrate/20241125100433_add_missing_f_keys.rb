class AddMissingFKeys < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :memberships, :servers, on_delete: :cascade
    add_foreign_key :messages, :servers, on_delete: :cascade
  end
end
