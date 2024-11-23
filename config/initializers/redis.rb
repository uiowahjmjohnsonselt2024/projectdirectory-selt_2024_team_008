require 'redis'

Redis.current = Redis.new(
  host: ENV.fetch('REDIS_HOST', '127.0.0.1'),
  port: ENV.fetch('REDIS_PORT', 6379),
  password: ENV.fetch('REDIS_PASSWORD', nil),
  url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/0'),
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
)