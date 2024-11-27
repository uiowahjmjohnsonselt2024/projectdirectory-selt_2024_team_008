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
  after_create :store_original_creator
  # before_destroy :prevent_creator_nullification
  before_destroy :reassign_creator

  def user_can_access?(user)
    return false unless user

    has_access = users.where(id: user.id).exists?
    Rails.logger.info("Checking access for user #{user.id} on server #{id}: #{has_access}")
    has_access
  end

  def remove_user(user)
    membership = memberships.find_by(user: user)

    unless membership
      Rails.logger.warn("Attempted to remove user #{user.id} from server #{id}, but no membership found")
      return
    end

    ActiveRecord::Base.transaction do
      # Handle creator reassignment
      if creator == user
        Rails.logger.info("Reassigning creator role for server #{id}")
        new_creator = memberships.where.not(user_id: user.id).first&.user
        if new_creator
          Rails.logger.info("New creator assigned: user #{new_creator.id}")
          update!(creator_id: new_creator.id)
        else
          Rails.logger.info("Checking if original creator exists for server #{id}")

          # Validate the original creator exists
          if User.exists?(id: original_creator_id)
            Rails.logger.info("Reassigning creator to original creator #{original_creator_id}")
            update!(creator_id: original_creator_id)
          end
        end
      end

      # Destroy associated messages for the user
      messages.where(user: user).destroy_all

      Rails.logger.info("Removing user #{user.id} from server #{id}")
      membership.destroy!
    end
  rescue ActiveRecord::InvalidForeignKey => e
    Rails.logger.error("Failed to remove membership for user #{user.id} in server #{id}: #{e.message}")
    raise
  end

  private

  def add_creator_to_memberships
    return if memberships.exists?(user: creator)

    memberships.create!(user: creator) if creator.present?
    Rails.logger.info("Added creator #{creator.id} to memberships for server #{id}")
  rescue StandardError => e
    Rails.logger.error("Failed to add creator to memberships for server #{id}: #{e.message}")
  end

  def store_original_creator
    update!(
      original_creator_name: creator.username,
      original_creator_email: creator.email,
      original_creator_id: creator.id
    )
  end

  def reassign_creator
    return unless creator_id.present?

    # Reassign creator if possible
    new_creator = memberships.where.not(user_id: creator_id).first&.user
    if new_creator
      update!(creator_id: new_creator.id)
    elsif original_creator_id.present? && User.exists?(id: original_creator_id)
      update!(creator_id: original_creator_id)
    else
      update!(creator_id: nil) # Safe nullification if constraints allow
    end

  end


end