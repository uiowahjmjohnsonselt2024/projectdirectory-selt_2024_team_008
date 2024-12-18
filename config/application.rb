# frozen_string_literal: true

require File.expand_path('boot', __dir__)

require 'rails/all'
require "action_cable/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# ShardsOfTheGrid module is the module for the application
module ShardsOfTheGrid
  # ShardsOfTheGrid::Application is the main configuration class for the Rails application.
  # It configures application-wide settings and dependencies.
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    # config.active_record.raise_in_transactional_callbacks = true.      Removed in Rails 5

    # config.active_storage.service = :local  # not using any cloud services
    config.assets.enabled = true
    config.assets.paths << Rails.root.join("app", "assets", "javascripts")


    # Explicitly set legacy_connection_handling to false
    config.active_record.legacy_connection_handling = false

    # config.after_initialize do
    #   ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")
    # end

    config.assets.initialize_on_precompile = false

    # Active Record Encryption configuration
    config.active_record.encryption.primary_key = Rails.application.credentials.dig(:active_record_encryption, :primary_key)
    config.active_record.encryption.deterministic_key = Rails.application.credentials.dig(:active_record_encryption, :deterministic_key)
    config.active_record.encryption.key_derivation_salt = Rails.application.credentials.dig(:active_record_encryption, :key_derivation_salt)


  end

end