# frozen_string_literal: true

class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :server, optional: true
  belongs_to :game, optional: true

  # Validation to ensure a user can only join a server once
  validates :user_id, uniqueness:{
    scope: :server_id, message: 'User is already a member of this server'
  }

  # Scopes for common queries
  scope :for_user, ->(user) { where(user: user) }
  scope :for_server, ->(server) { where(server: server) }
  scope :for_game, ->(game) { where(game: game) }

  after_create :log_membership_creation

  private

  def log_membership_creation
    if server_id
      Rails.logger.info "Membership created: User #{user_id} joined Server #{server_id}"
    elsif game_id
      Rails.logger.info "Membership created: User #{user_id} joined Game #{game_id}"
    else
      Rails.logger.info "Membership created: User #{user_id} has no specific association"
    end
  end
end