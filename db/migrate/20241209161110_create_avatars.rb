class CreateAvatars < ActiveRecord::Migration[7.0]
  def change
    create_table :avatars do |t|
      t.references :user, null: false, foreign_key: true
      t.references :hat, foreign_key: { to_table: :items }, null: true
      t.references :top, foreign_key: { to_table: :items }, null: true
      t.references :bottoms, foreign_key: { to_table: :items }, null: true
      t.references :shoes, foreign_key: { to_table: :items }, null: true
      t.references :accessories, foreign_key: { to_table: :items }, null: true
      t.binary :avatar_image
      t.timestamps
    end
  end
end
