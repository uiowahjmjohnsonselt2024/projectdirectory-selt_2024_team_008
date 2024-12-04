# Session Store Configuration for RedisCloud
session_url = ENV.fetch('REDISCLOUD_URL', 'redis://127.0.0.1:6379/0') # Use RedisCloud URL or fallback to local Redis
secure = Rails.env.production?
key = Rails.env.production? ? "_shards_of_the_grid_session" : "_shards_of_the_grid_session_#{Rails.env}"
domain = Rails.env.production? ? ENV.fetch("DOMAIN_NAME", nil) : "localhost"

if Rails.env.production?
  puts "D, Using Redis store"
  Rails.application.config.session_store :redis_store,
                                         url: session_url,
                                         expire_after: 90.minutes,
                                         key: key,
                                         domain: domain,
                                         threadsafe: true,
                                         secure: secure,
                                         same_site: :lax,
                                         httponly: true

elsif Rails.env.development? || Rails.env.test?
  puts "D, Using Cookie store"
  Rails.application.config.session_store :cookie_store
else
  puts "E, Environment not matched"
end

# Rails.application.config.session_store :cookie_store
