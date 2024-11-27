class CreateMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :server, null: false, foreign_key: true
      t.timestamps
    end
    add_index :memberships, [:user_id, :server_id], unique: true
  end
end
