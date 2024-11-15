source 'https://rubygems.org'


gem 'rails', '~> 7.0'  # Ensure compatibility with Railties and Rails components

# Use PostgreSQL as the database for Active Record (recommended over sqlite3 for production)
gem 'pg', '>= 1.1', '< 2.0'

# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
# gem 'coffee-script', '~> 2.4'
# gem 'coffee-script-source', '>= 1.12.2'
# gem 'coffee-rails', '~> 5.0'

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
# gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

gem 'rubocop', require: false
gem 'rubocop-rails', require: false # For Rails-specific cops (recommended for Rails projects)
gem 'rubocop-rspec', require: false
gem 'rubocop-rspec_rails', require: false

# Gemfile
gem 'sprockets-rails'  # Manages the asset pipeline in Rails
gem 'sprockets'        # Core asset pipeline library


# Group gems for development and testing
group :development, :test do
  # Better errors and debugging
  gem 'byebug'
  gem 'rspec-rails', '~> 5.0' # Updated for Rails 7
  # Pry is an alternative for debugging
  gem 'pry-rails'

  gem 'sqlite3', '~> 1.4'
end

group :development do
  # Web console to debug from the browser
  gem 'web-console', '~> 4.2.0'
  # Spring for faster Rails command execution
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.1'
end

# For production deployment
group :production do
  
end

gem 'devise', '~> 4.9'
gem 'puma', '~> 6.0'
gem 'execjs', '>= 2.9'
gem 'dotenv-rails'