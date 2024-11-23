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


  has_many :created_servers, class_name: 'Server', foreign_key: 'creator_id'
  has_many :memberships
  has_many :joined_servers, through: :memberships, source: :server
  has_many :messages

  has_one :shard_account, dependent: :destroy
  after_create :initialize_shard_account
  after_create :assign_starting_mystery_boxes


  has_many :user_items
  has_many :items, through: :user_items

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
    Rails.cache.fetch("user_#{id}_online", raw: true) || false
  end

  private

  def initialize_shard_account
    create_shard_account(balance: 0) # Start with 0 balance
  end

  def assign_starting_mystery_boxes
    mystery_box = Item.find_by(item_name: "Mystery Box")
    user_item = self.user_items.find_or_initialize_by(item: mystery_box)
    user_item.quantity ||= 0
    user_item.quantity += 5
    user_item.save
  end
end
