class CreateShardAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :shard_accounts do |t|
      t.references :user, foreign_key: true
      t.integer :balance

      t.timestamps
    end
  end
end
