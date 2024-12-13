class Game < ApplicationRecord
  belongs_to :creator, class_name: "User"

  has_one :server, dependent: :destroy # Each game has one associated chat room

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :tiles, dependent: :destroy

  enum status: { waiting: 0, in_progress: 1, completed: 2 }

  validates :name, presence: true # Optional: Validations for game lifecycle and integrity
  validates :creator_id, presence: true, unless: -> { User.reassigning? }
  validates :server_id, presence: true, unless: -> { User.reassigning? }

  attribute :user_colors, :json, default: -> { {} }

  before_create :initialize_user_colors
  after_create :initialize_grid

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

  # Update a tile's occupant and owner
  def update_tile(x, y, username)
    tile = tiles.find_by(x: x, y: y)
    return unless tile

    ActiveRecord::Base.transaction do
      # Clear any previous position for the username
      tiles.where(occupant: username).update_all(occupant: nil)

      # Update the new tile
      tile.update!(
        occupant: username,
        owner: tile.owner || username,
        color: user_colors[username] || assign_color(username)
      )
    end
  end

  # Find the position of a user on the grid
  def find_user_position(username)
    tile = tiles.joins(:occupant_user).find_by(users: { username: username })
    tile ? [tile.x, tile.y] : nil
  end

  # Check if a tile is empty
  def tile_empty?(x, y)
    tile = tiles.find_by(x: x, y: y)
    tile&.occupant_id.nil?
  end

  def find_farthest_tile
    occupied_or_owned_tiles = tiles.where.not(occupant_id: nil).or(tiles.where.not(owner: nil))
    if occupied_or_owned_tiles.empty?
      # If no tiles are occupied or owned, default to the top-left corner
      return tiles.find_by(x: 0, y: 0)
    end

    # Calculate distances for all tiles
    tiles.reject { |tile| tile.occupant_id.present? || tile.owner.present? }
         .max_by do |tile|
      # Compute the minimum distance from this tile to any occupied or owned tile
      occupied_or_owned_tiles.map do |occupied_tile|
        distance(tile.x, tile.y, occupied_tile.x, occupied_tile.y)
      end.min
    end
  end

  private

  def distance(x1, y1, x2, y2)
    [(x1 - x2).abs, (y1 - y2).abs].max
  end

  def initialize_user_colors
    self.user_colors ||= {}
  end

  def initialize_grid
    image_sources = %w[background1.png background2.png background3.png background4.png background5.png background6.png]

    (0...10).each do |y|
      (0...10).each do |x|
        tiles.create!(x: x, y: y, owner: nil, occupant_id: nil, color: nil, image_source: image_sources.sample)
      end
    end
  end

end