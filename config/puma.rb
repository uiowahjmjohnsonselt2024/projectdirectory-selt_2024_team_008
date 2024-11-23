# Specifies the number of worker processes to boot in clustered mode
# Workers use threads for concurrency
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Specifies the minimum and maximum threads per worker
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# Preload the app before forking workers for better performance
preload_app!

# Specifies the port Heroku will use
port ENV.fetch("PORT") { 3000 }

# Specifies the environment
environment ENV.fetch("RACK_ENV") { "production" }

# On worker boot, reconnect to the database
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end