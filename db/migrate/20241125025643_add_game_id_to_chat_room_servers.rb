class AddGameIdToChatRoomServers < ActiveRecord::Migration[7.0]
  def change
    add_reference :servers, :game, foreign_key: true
  end
end