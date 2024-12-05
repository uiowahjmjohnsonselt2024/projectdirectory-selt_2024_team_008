class RenameOriginalCreatorNameToUsernameInServers < ActiveRecord::Migration[7.0]
  def change
    if column_exists?(:servers, :original_creator_name)
      rename_column :servers, :original_creator_name, :original_creator_username
    end
  end
end