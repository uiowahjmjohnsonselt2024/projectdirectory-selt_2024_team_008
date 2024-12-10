class Tile < ApplicationRecord
  belongs_to :game

  validates :x, :y, presence: true
  validates :x, :y, numericality: { greater_than_or_equal_to: 0 }
end