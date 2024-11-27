# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  # Virtual attribute for authenticating by either username or email
  attr_accessor :login

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: %w[admin user guest], message: "%{value} is not a valid role" }

  has_many :created_games, class_name: 'Game', foreign_key: 'creator_id', dependent: :nullify
  has_many :created_servers, class_name: 'Server', foreign_key: 'creator_id', dependent: :nullify
  has_many :joined_servers, through: :memberships, source: :server
  has_many :messages, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :user_items
  has_many :items, through: :user_items
  
  has_one :shard_account, dependent: :destroy
  
  after_create :initialize_shard_account
  after_create :assign_starting_mystery_boxes

  # Override Devise's find_for_database_authentication method
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(['lower(username) = :value OR lower(email) = :value',
                                    { value: login.downcase }]).first
    else
      where(conditions.to_h).first
    end
  end

  def online?
    Rails.cache.read("user_#{id}_online") || (last_seen_at.present? && last_seen_at > 3.minutes.ago)
  end

  private

  def initialize_shard_account
    create_shard_account(balance: 0) # Start with 0 balance
  end

  def assign_starting_mystery_boxes
    Rails.logger.debug "assign_starting_mystery_boxes called for user #{id}"
    mystery_box = Item.find_by(item_name: "Mystery Box")
    if mystery_box
      user_item = self.user_items.find_or_initialize_by(item: mystery_box)
      user_item.quantity ||= 0
      user_item.quantity += 5
      user_item.save!
    else
      Rails.logger.error("Failed to find or create Mystery Box item")
    end
  end
end