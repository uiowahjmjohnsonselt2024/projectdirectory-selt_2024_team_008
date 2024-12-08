require 'openai'

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_API_KEY')
  # Optionally, set your organization ID if applicable
  # config.organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID', nil)
end