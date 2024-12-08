# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

Rails.application.config.assets.precompile += %w[application.js]


# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w( application.js application.css welcome.js welcome.css main_menu.css main_menu.js devise/devise.css devise/login.css devise/logout.css devise/password_reset.css devise/signup.css game_ui.css game_ui.js chat_room.css chat_room.js server.css servers.js inventory.css mystery_boxes.css mystery_boxes.js sessions.css channels/server_channel.js channels/game_logic_channel.js channels/consumer.js )
