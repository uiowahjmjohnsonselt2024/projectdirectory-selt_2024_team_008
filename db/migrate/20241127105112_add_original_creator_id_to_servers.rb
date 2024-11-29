class AddOriginalCreatorIdToServers < ActiveRecord::Migration[7.0]
  def change
    add_column :servers, :original_creator_id, :integer
  end
end
