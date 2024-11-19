# frozen_string_literal: true

class Server < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :memberships
  has_many :users, through: :memberships
  has_many :messages

  after_create :add_creator_to_memberships

  def user_can_access?(user)
    users.exists?(user.id)
  end

  def remove_user(user)
    memberships.find_by(user: user)&.destroy
  end

  private

  def add_creator_to_memberships
    memberships.create(user: creator)
  end

end
