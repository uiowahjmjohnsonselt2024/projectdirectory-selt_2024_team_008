class CombineOriginalCreatorToServers < ActiveRecord::Migration[7.0]
  def change
    add_column :servers, :original_creator_username, :string
    add_column :servers, :original_creator_email, :string
    add_column :servers, :original_creator_id, :bigint # Use the correct type

    # Adjust the column type if necessary (for PostgreSQL)
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      change_column :servers, :original_creator_id, :integer, using: 'original_creator_id::integer', null: true
    else
      change_column :servers, :original_creator_id, :integer, null: true
    end
  end
end