class Tile < ApplicationRecord
  belongs_to :game

  validates :x, :y, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :image_source, presence: true, allow_nil: true
  validates :task_type, inclusion: { in: %w[ADD TILE TYPES HERE],
                                     message: "%{value} is not a valid task type"}, allow_nil: true
end