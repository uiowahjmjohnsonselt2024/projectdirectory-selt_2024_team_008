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
  attribute :user_colors, :json, default: -> { {} }

  before_create :initialize_user_colors

  # Assign a color to a user if they don't already have one
  def assign_color(username)
    preset_colors = %w[tile-color-1 tile-color-2 tile-color-3 tile-color-4 tile-color-5 tile-color-6]
    return user_colors[username] if user_colors[username] # Return existing color if already assigned

    # Assign next available color
    unused_colors = preset_colors - user_colors.values
    user_colors[username] = unused_colors.first || preset_colors.sample
    save!
    user_colors[username]
  end

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

  private

  def initialize_user_colors
    self.user_colors ||= {}
  end

end