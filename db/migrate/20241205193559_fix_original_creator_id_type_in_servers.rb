class FixOriginalCreatorIdTypeInServers < ActiveRecord::Migration[7.0]
  def change
    change_column :servers, :original_creator_id, :integer, null: true
  end
end