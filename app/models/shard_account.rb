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

  # Converts shards to the equivalent cost in the selected currency
  def self.convert_to_currency(shards, target_currency)
    return 'Invalid input' if shards <= 0 || target_currency.blank?

    if target_currency.downcase != "usd"
      exchange_rate = fetch_exchange_rate(target_currency)
    else
      exchange_rate = 1
    end
    return 'Error fetching exchange rate' if exchange_rate.nil?

    # Calculate the cost in USD and convert to target currency
    cost_in_usd = self.shards_to_usd(shards)
    (cost_in_usd * exchange_rate).round(2)
  end

  def self.usd_to_shards(usd)
    (usd / 0.75).round(2)
  end

  def self.shards_to_usd(shards)
    (shards * 0.75).round(2)
  end

  protected

  @CONVERSION_API_KEY

  def self.fetch_exchange_rate(currency)
      api_url = "https://v6.exchangerate-api.com/v6/#{@CONVERION_API_KEY}/latest/USD"
    rescue
      raise ArgumentError, 'Problem in conversion, is API key set?'
    response = Net::HTTP.get(URI(api_url))
    data = JSON.parse(response)

    return data['conversion_rates'][currency] if data['conversion_rates'] && data['conversion_rates'][currency]

    nil
  rescue StandardError => e
    Rails.logger.error("Exchange rate fetch failed: #{e.message}")
    nil
  end
end
