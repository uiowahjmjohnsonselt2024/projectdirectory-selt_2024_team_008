# frozen_string_literal: true

class Server < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :messages, dependent: :destroy

  validates :name, presence: true

  after_create :add_creator_to_memberships

  def user_can_access?(user)
    has_access = users.exists?(user.id)
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
    unless memberships.exists?(user: creator)
      memberships.create!(user: creator)
      Rails.logger.info("Added creator #{creator.id} to memberships for server #{id}")
    end
  rescue StandardError => e
    Rails.logger.error("Failed to add creator to memberships for server #{id}: #{e.message}")
  end

end