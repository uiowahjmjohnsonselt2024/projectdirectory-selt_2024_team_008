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

  has_many :created_servers, class_name: 'Server', foreign_key: 'creator_id'
  has_many :memberships
  has_many :joined_servers, through: :memberships, source: :server
  has_many :messages

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

end