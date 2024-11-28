class AddCaseInsensitiveIndexToUsers < ActiveRecord::Migration[7.0]
  def up
    remove_index :users, :username
    execute <<-SQL
      CREATE UNIQUE INDEX index_users_on_lower_username ON users (LOWER(username));
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX index_users_on_lower_username;
    SQL
    add_index :users, :username, unique: true
  end
end
