class AddCascadeToTilesGameForeignKey < ActiveRecord::Migration[7.0]
  def change
    if foreign_key_exists?(:tiles, :games)
      remove_foreign_key :tiles, :games
    end

    add_foreign_key :tiles, :games, on_delete: :cascade
  end
end