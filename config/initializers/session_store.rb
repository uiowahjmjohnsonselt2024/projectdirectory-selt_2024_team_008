if Rails.env.production?
  puts "D, Using Redis store"
  Rails.application.config.session_store :redis_store, {
    servers: [
      {
        url: ENV['REDIS_URL'], # Use Redis in production
        namespace: 'session'
      }
    ],
    expire_after: 90.minutes,
    key: '_shards_of_the_grid_session'
  }
elsif Rails.env.development? || Rails.env.test?
  puts "D, Using Cookie store"
  Rails.application.config.session_store :cookie_store
else
  puts "E, Environment not matched"
end

# Rails.application.config.session_store :cookie_store

