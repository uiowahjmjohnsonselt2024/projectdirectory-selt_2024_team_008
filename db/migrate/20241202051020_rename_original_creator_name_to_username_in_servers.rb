class RenameOriginalCreatorNameToUsernameInServers < ActiveRecord::Migration[7.0]
  def change
    rename_column :servers, :original_creator_name, :original_creator_username
  end
end