class AddOriginalCreatorToServers < ActiveRecord::Migration[7.0]
  def change
    add_column :servers, :original_creator_username, :string
    add_column :servers, :original_creator_email, :string
    add_column :servers, :original_creator_id, :id
  end
end
