class FixOriginalCreatorIdTypeInServers < ActiveRecord::Migration[7.0]
  def change
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      change_column :servers, :original_creator_id, :integer, using: 'original_creator_id::integer', null: true
    else
      change_column :servers, :original_creator_id, :integer, null: true
    end
  end
end