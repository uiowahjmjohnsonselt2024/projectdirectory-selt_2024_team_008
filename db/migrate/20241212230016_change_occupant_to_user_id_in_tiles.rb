class ChangeOccupantToUserIdInTiles < ActiveRecord::Migration[7.0]
  def change
    # Check if the `occupant` column exists before attempting to remove it
    if column_exists?(:tiles, :occupant)
      remove_column :tiles, :occupant, :string
    end

    # Check if the `occupant_id` column does not already exist before adding it
    unless column_exists?(:tiles, :occupant_id)
      add_column :tiles, :occupant_id, :integer
    end

    # Add a foreign key from tiles to users if it does not already exist
    unless foreign_key_exists?(:tiles, :users, column: :occupant_id)
      add_foreign_key :tiles, :users, column: :occupant_id
    end
  end
end