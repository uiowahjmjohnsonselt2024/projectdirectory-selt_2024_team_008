class Game < ApplicationRecord
  belongs_to :creator, class_name: "User"
  has_one :server, dependent: :delete # Each game has one associated chat room
  has_many :users, through: :memberships

  enum game_status: { waiting: 0, in_progress: 1, completed: 2 }

  validates :name, presence: true # Optional: Validations for game lifecycle and integrity
  validates :creator_id, presence: true
  validates :server_id, presence: true

  before_validation :set_default_status, on: :create
  after_create :initialize_grid, if: :new_record?

  attribute :grid, :json, default: -> { Array.new(6) { Array.new(6, nil) } }

  private

  def set_default_status
    self.game_status ||= :waiting
  end
  def initialize_grid
  self.grid = Array.new(6) { Array.new(6, nil) }.to_json
  save!
  end

end