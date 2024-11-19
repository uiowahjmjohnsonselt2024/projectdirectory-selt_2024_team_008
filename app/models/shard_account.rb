class ShardAccount < ApplicationRecord
  belongs_to :user

  # Validations to ensure data integrity
  validates :balance, numericality: { greater_than_or_equal_to: 0 }

  SHARD_PACKAGES = [
    { price: 7.50, shards: 10 },
    { price: 15.00, shards: 20 },
    { price: 30.00, shards: 40 },
    { price: 75.00, shards: 100 },
    { price: 150.00, shards: 200 }
  ].freeze
  def create
    @balance = 0
  end

  def self.usd_to_shards(usd)
    (usd / 0.75).round(2)
  end

  def self.shards_to_usd(shards)
    (shards * 0.75).round(2)
  end
end
