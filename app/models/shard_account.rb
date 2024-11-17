class ShardAccount < ApplicationRecord
  belongs_to :user

  def self.usd_to_shards(usd)
    (usd / 0.75).round(2)
  end

  def self.shards_to_usd(shards)
    (shards * 0.75).round(2)
  end
end