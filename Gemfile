# frozen_string_literal: true

source 'https://rubygems.org'

# Specify the Ruby version
ruby '3.2.2'

# Rails 7 (latest stable)
gem 'rails', '~> 7.0.0'

# Use PostgreSQL as the database for Active Record (recommended over sqlite3 for production)
gem 'pg', '>= 1.1', '< 2.0'

# Use SCSS for stylesheets
# gem 'sassc-rails', '~> 2.1'

# Use CSS bundling with esbuild (recommended in Rails 7)
# gem 'cssbundling-rails'

# JavaScript bundling for assets (Rails 7 default setup)
# gem 'jsbundling-rails'

gem 'jquery-rails'

gem 'turbolinks', '~> 5'


# Use Uglifier as compressor for JavaScript assets if needed
# gem 'uglifier', '>= 4.2.0'

# Use CoffeeScript if required, though many Rails 7 apps use JavaScript modules instead
# gem 'coffee-rails', '~> 5.0'

# Use Hotwire for real-time updates in Rails 7
gem 'hotwire-rails'

# Use Turbo for improved navigation without full page reloads
gem 'turbo-rails'

# Use jbuilder for JSON APIs
gem 'jbuilder', '~> 2.11'

# Authentication library (optional, but Devise is commonly used)
# gem 'devise', '~> 4.8'

# Security and authentication utilities
gem 'bcrypt', '~> 3.1.18'

# Generate documentation
gem 'sdoc', '~> 2.0', group: :doc

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
end

group :development do
  # Web console to debug from the browser
  gem 'web-console', '~> 4.2.0'

  # Spring for faster Rails command execution
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.1'
end

# For image processing in Rails 7 (optional, use if you need image uploads)
gem 'image_processing', '~> 1.2'

# For production deployment
group :production do
  gem 'puma', '~> 5.6' # High-performance web server for production
end
