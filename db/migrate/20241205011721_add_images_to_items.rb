class AddImagesToItems < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :images, :string
  end
end
