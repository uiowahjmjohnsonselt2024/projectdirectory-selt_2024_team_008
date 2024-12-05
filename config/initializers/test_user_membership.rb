unless ENV['RAILS_GROUPS'] == 'assets'
  if ActiveRecord::Base.connection.table_exists?('users') && ActiveRecord::Base.connection.table_exists?('servers')
    Rails.application.config.to_prepare do
      test_user = User.find_by(email: 'test_user@example.com')
      test_server = Server.find_by(name: 'Test Server')

      if test_user && test_server
        Membership.find_or_create_by!(user: test_user, server: test_server)
        Rails.logger.info("Ensured test_user has membership to Test Server")
      end
    end
  end
end