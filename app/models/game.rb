class Game < ApplicationRecord
  belongs_to :creator, class_name: "User"

  has_one :server, dependent: :destroy # Each game has one associated chat room

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  enum status: { waiting: 0, in_progress: 1, completed: 2 }

  validates :name, presence: true # Optional: Validations for game lifecycle and integrity
  validates :creator_id, presence: true, unless: -> { User.reassigning? }
  validates :server_id, presence: true, unless: -> { User.reassigning? }

  attribute :grid, :json, default: -> { Array.new(10) { Array.new(10, { owner: nil, occupant: nil, color: nil}) } }
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
  end

  def update_grid(x, y, username)
    # Clear the user's previous position
    grid.each_with_index do |row, row_index|
      row.each_with_index do |cell, col_index|
        if cell[:occupant] == username
          Rails.logger.debug("Clearing occupant from previous position: (#{col_index}, #{row_index})")
          cell[:occupant] = nil
        end
      end
    end

    # Validate the new coordinates before setting
    raise "Invalid coordinates (#{x}, #{y})" unless grid[y] && grid[y][x]

    user_color = user_colors[username] || assign_color(username)

    # Set the new position for the user
    grid[y][x][:occupant] = username
    grid[y][x][:owner] ||= username # Set owner if it's not already set
    grid[y][x][:color] = user_color

    Rails.logger.debug("Grid after update: #{grid.to_json}")
    save!
  end

  def find_user_position(username)
    position = grid.flatten.index(username)
    return nil unless position

    [position % grid.first.size, position / grid.first.size]
  end

  def purchase_tile(x, y, username)
    tile = grid[y][x]
    return false unless tile[:owner].nil?

    tile[:owner] = username
    tile[:color] = user_colors[username]
    save!
  end

  def assign_starting_position(username)
    Rails.logger.debug "Game users: #{users.pluck(:username)}"
    Rails.logger.debug "Assigning position for username: #{username}"

    # Calculate starting position based on user index
    user_index = users.pluck(:username).index(username) # Use pluck for performance
    starting_positions = [
      [0, 0], [9, 0], [0, 9], [9, 9] # Corner positions for a 10x10 grid
    ]
    initial_position = starting_positions[user_index % starting_positions.length]

    # Check for availability or find the next open spot
    x, y = initial_position
    Rails.logger.debug "Initial position for #{username}: (#{x}, #{y})"

    until grid[y][x][:owner].nil? && grid[y][x][:occupant].nil?
      Rails.logger.debug "Position (#{x}, #{y}) is occupied or owned. Searching for next available spot."
      x += 1
      if x >= grid.first.size # Wrap to the next row
        x = 0
        y += 1
        y = 0 if y >= grid.size # Wrap back to the top
      end
    end

    Rails.logger.debug "Assigned position for #{username}: (#{x}, #{y})"

    update_grid(x, y, username)
    reload
    [x, y]
  end

  def owns_tile?(x, y, username)
    grid[y][x][:owner] == username
  end

  def tile_empty?(x, y)
    grid[y][x].nil?
  end

  private

  def initialize_user_colors
    self.user_colors ||= {}
  end

end