class Game < ApplicationRecord
  belongs_to :creator, class_name: "User"

  has_one :server, dependent: :delete # Each game has one associated chat room

  has_many :users, through: :memberships

  enum status: { waiting: 0, in_progress: 1, completed: 2 }

  validates :name, presence: true # Optional: Validations for game lifecycle and integrity
  validates :creator_id, presence: true, unless: -> { User.reassigning? }
  validates :server_id, presence: true, unless: -> { User.reassigning? }

  attribute :grid, :json, default: -> { Array.new(6) { Array.new(6, nil) } }

  private

end