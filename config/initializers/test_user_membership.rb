# config/initializers/test_user_membership.rb
Rails.logger.info("test_user_membership.rb initializer loaded")
Rails.application.config.to_prepare do
  Rails.logger.info("Initializing test_user_membership.rb...")

  test_user = User.find_by(email: 'test_user@example.com')
  test_server = Server.find_by(name: 'Test Server')

  if test_user && test_server
    Membership.find_or_create_by!(user: test_user, server: test_server)
    Rails.logger.info("Ensured test_user has membership to Test Server")
  else
    missing = []
    missing << "test_user" if test_user.nil?
    missing << "test_server" if test_server.nil?
    Rails.logger.warn("Could not ensure test_user membership: Missing #{missing.join(' and ')}")
  end
end