class AddUserColorsToGames < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:games, :user_colors)
      add_column :games, :user_colors, :json, default: {}
    end
  end
end