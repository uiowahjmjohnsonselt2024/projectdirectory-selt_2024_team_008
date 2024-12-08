# frozen_string_literal: true

class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :server, optional: true
  belongs_to :game, optional: true

  # Validation to ensure a user can only join a unique combination of server and game
  validates :user_id, uniqueness: {
    scope: [:server_id, :game_id],
    message: 'User is already a member of this server or game'
  }

  # Scopes for common queries
  scope :for_user, ->(user) { where(user: user) }
  scope :for_server, ->(server) { where(server: server) }
  scope :for_game, ->(game) { where(game: game) }

  after_create :log_membership_creation

  private

  def log_membership_creation
    if server_id && game_id
      Rails.logger.info "Membership created: User #{user_id} joined Game #{game_id}, Server #{server_id}"
    end
  end
end