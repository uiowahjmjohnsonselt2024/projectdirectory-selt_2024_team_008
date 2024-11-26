class CreateGamesTable < ActiveRecord::Migration[7.0]
  def change
    create_table :games do |t|
      t.string :name, null: false # Game name or identifier
      t.integer :creator_id, null: false # User who created the game
      t.integer :status, default: 0, null: false # Game status (e.g., pending, in-progress, completed)
      t.string :external_server_url # URL or identifier for the external game server
      t.references :server, foreign_key: true # Link to the chat room server
      t.datetime :started_at # When the game started
      t.datetime :ended_at # When the game ended
      t.timestamps
    end

    # add_foreign_key :games, :users, column: :creator_id
    add_index :games, :creator_id
  end
end