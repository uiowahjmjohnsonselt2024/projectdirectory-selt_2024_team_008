# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  # Virtual attribute for authenticating by either username or email
  attr_accessor :login
  
  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true

  has_one :shard_account, dependent: :destroy
  after_create :initialize_shard_account

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

  private

  def initialize_shard_account
    create_shard_account(balance: 0) # Start with 0 balance
  end

end
