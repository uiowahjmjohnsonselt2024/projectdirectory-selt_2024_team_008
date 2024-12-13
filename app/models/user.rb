# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable,
         :omniauthable, omniauth_providers: [:google_oauth2]


  # Virtual attribute for authenticating by either username or email
  attr_accessor :login
  attr_accessor :reassigning

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: %w[admin user guest], message: "%{value} is not a valid role" }

  has_many :memberships, dependent: :destroy
  has_many :joined_servers, through: :memberships, source: :server

  has_many :created_games, class_name: 'Game', foreign_key: 'creator_id', dependent: :nullify
  has_many :created_servers, class_name: 'Server', foreign_key: 'creator_id', dependent: :nullify
  has_many :messages, dependent: :destroy

  has_many :user_items
  has_many :items, through: :user_items
  
  has_one :shard_account, dependent: :destroy
  
  after_create :initialize_shard_account
  after_create :assign_starting_mystery_boxes
  before_destroy :reassign_creator_roles

  has_one :avatar, dependent: :destroy
  after_create :create_default_avatar

  def create_default_avatar
    avatar = build_avatar
    image_path = Rails.root.join('app', 'assets', 'images', 'defaultAvatar.png')

    if File.exist?(image_path)
      avatar.avatar_image = File.binread(image_path)
    else
      Rails.logger.warn "Default avatar image not found at #{image_path}"
    end

    avatar.save

  end

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

  def self.from_omniauth(auth)
    return nil if auth.info.email.nil? || auth.uid.nil?

    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.username = auth.info.email.split('@').first
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


  def self.reassigning?
    Thread.current[:reassigning] || false
  end

  def self.reassigning=(value)
    Thread.current[:reassigning] = value
  end

  def reassign_creator_roles
    User.reassigning = true
    ActiveRecord::Base.transaction do
      created_servers.each do |server|
        new_creator = User.where("id NOT IN (?)", id).first
        if new_creator
          server.update!(creator_id: new_creator.id)
        else
          if User.exists?(id: server.original_creator_id)
            server.update!(
              creator_id: server.original_creator_id,
              original_creator_username: server.original_creator_username || username,
              original_creator_email: server.original_creator_email || email
            )
          else
            server.update!(creator_id: nil)
          end
        end
      end

      created_games.each do |game|
        new_creator = User.where("id NOT IN (?)", id).first
        if new_creator
          game.update!(creator_id: new_creator.id)
        else
          game.update!(creator_id: nil)
        end
      end
    end
    Rails.logger.info("Reassigning complete for user ID: #{id}")
  ensure
    User.reassigning = false # Reset after completion
  end
end