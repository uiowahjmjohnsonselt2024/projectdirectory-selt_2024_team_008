# frozen_string_literal: true

class Server < ApplicationRecord
  belongs_to :creator, class_name: 'User', optional: true
  belongs_to :game, optional: true
  has_many :memberships, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :users, through: :memberships

  validates :name, presence: true
  validates :creator, presence: true, on: :create

  after_create :add_creator_to_memberships
  before_destroy :prevent_creator_nullification

  def user_can_access?(user)
    return false unless user

    has_access = users.where(id: user.id).exists?
    Rails.logger.info("Checking access for user #{user.id} on server #{id}: #{has_access}")
    has_access
  end

  def remove_user(user)
    membership = memberships.find_by(user: user)
    if membership
      Rails.logger.info("Removing user #{user.id} from server #{id}")
      membership.destroy
    else
      Rails.logger.warn("Attempted to remove user #{user.id} from server #{id}, but no membership found")
    end
  end

  private

  def add_creator_to_memberships
    return if memberships.exists?(user: creator)

    memberships.create!(user: creator) if creator.present?
    Rails.logger.info("Added creator #{creator.id} to memberships for server #{id}")
  rescue StandardError => e
    Rails.logger.error("Failed to add creator to memberships for server #{id}: #{e.message}")
  end

  def prevent_creator_nullification
    # Ensure creator_id is not set to NULL during deletion
    if persisted? && creator_id.nil?
      raise ActiveRecord::Rollback, "Cannot nullify creator_id during server destruction"
    end
  end

end