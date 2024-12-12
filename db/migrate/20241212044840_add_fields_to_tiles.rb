class AddFieldsToTiles < ActiveRecord::Migration[7.0]
  def change
    add_column :tiles, :image_source, :string unless column_exists?(:tiles, :image_source)
    add_column :tiles, :task_type, :string unless column_exists?(:tiles, :task_type)
    add_column :tiles, :task_last_completed, :datetime unless column_exists?(:tiles, :task_last_completed)
  end
end