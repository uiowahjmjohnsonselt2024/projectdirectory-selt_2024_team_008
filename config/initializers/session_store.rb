# frozen_string_literal: true

# Be sure to restart your server when you modify this file.


Rails.application.config.session_store :redis_store, {
  servers: [
    {
      url: ENV['REDIS_URL'], # Use the full Redis URL from the environment variable
      namespace: 'session'
    }
  ],
  expire_after: 90.minutes,
  key: '_shards_of_the_grid_session'
}