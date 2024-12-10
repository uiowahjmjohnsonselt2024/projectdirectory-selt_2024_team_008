class CreateCards < ActiveRecord::Migration[7.0]
  def change
    create_table :cards do |t|
      t.references :shard_account, null: false, foreign_key: true
      t.string :card_number_encrypted
      t.string :expiry_date
      t.string :cvv_encrypted
      t.text :billing_address

      t.timestamps
    end
  end
end
