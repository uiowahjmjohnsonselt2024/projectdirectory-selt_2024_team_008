class AddForeignKeyToGamesCreatorId < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :games, :users, column: :creator_id, on_delete: :nullify
  end
end