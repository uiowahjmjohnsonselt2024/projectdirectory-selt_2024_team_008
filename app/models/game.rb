class Game < ApplicationRecord
  belongs_to :creator, class_name: "User"

  has_one :server, dependent: :destroy # Each game has one associated chat room

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  enum status: { waiting: 0, in_progress: 1, completed: 2 }

  validates :name, presence: true # Optional: Validations for game lifecycle and integrity
  validates :creator_id, presence: true, unless: -> { User.reassigning? }
  validates :server_id, presence: true, unless: -> { User.reassigning? }

  attribute :grid, :json, default: -> { Array.new(6) { Array.new(6, nil) } }

  def update_grid(x, y, username)
    grid.each_with_index do |row, row_index|
      row.map! { |cell| cell == username ? nil : cell }
    end
    grid[y][x] = username
    save!
  end

  def find_user_position(username)
    position = grid.flatten.index(username)
    return nil unless position

    [position % grid.first.size, position / grid.first.size]
  end

  def tile_empty?(x, y)
    grid[y][x].nil?
  end

end