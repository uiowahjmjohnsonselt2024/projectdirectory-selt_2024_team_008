# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store, key: '_shards-of-the-grid_session'

Rails.application.config.session_store :redis_store, {
  servers: [
    {
      host: ENV['REDIS_HOST'],
      port: ENV['REDIS_PORT'],
      password: ENV['REDIS_PASSWORD'],
      db: 0,
      namespace: 'session'
    }
  ],
  expire_after: 90.minutes,
  key: '_your_app_session'
}