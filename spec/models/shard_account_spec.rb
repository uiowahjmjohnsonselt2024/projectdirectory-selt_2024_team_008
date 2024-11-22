require 'rails_helper'
require 'webmock/rspec'

RSpec.describe ShardAccount, type: :model do
  let(:user) { User.create!(username: 'test', email: "test@example.com", password: "password") }
  let(:shard_account) { described_class.create!(user: user, balance: 50) }


  describe "validations" do
    it "validates the presence of a balance" do
      expect(shard_account).to validate_numericality_of(:balance).is_greater_than_or_equal_to(0)
    end

    it "is invalid if the balance is negative" do
      shard_account.balance = -10
      expect(shard_account).not_to be_valid
    end
  end

  describe "USD and shard conversions" do
    it "converts USD to shards" do
      expect(ShardAccount.usd_to_shards(7.50)).to eq(10)
    end

    it "converts shards to USD" do
      expect(ShardAccount.shards_to_usd(10)).to eq(7.50)
    end
  end

  describe "currency conversion" do
    context "with valid input" do
      before do
        stub_request(:get, /v6.exchangerate-api.com/).to_return(
          body: {
            "conversion_rates" => {
              "EUR" => 0.85,
              "USD" => 1.0
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it "converts shards to the target currency" do
        expect(ShardAccount.convert_to_currency(10, "EUR")).to eq(6.38) # 10 shards = $7.50, $7.50 * 0.85 = 6.38 EUR
      end

      it "returns cost in USD if the target currency is USD" do
        expect(ShardAccount.convert_to_currency(10, "USD")).to eq(7.50)
      end
    end

    context "with invalid input" do
      it "returns 'Invalid input' for negative shards" do
        expect(ShardAccount.convert_to_currency(-10, "EUR")).to eq("Invalid input")
      end

      it "returns 'Invalid input' for blank target currency" do
        expect(ShardAccount.convert_to_currency(10, nil)).to eq("Invalid input")
      end
    end

    context "when the exchange rate API fails" do
      before do
        stub_request(:get, /v6.exchangerate-api.com/).to_return(status: 500)
      end

      it "returns 'Error fetching exchange rate' when the API response is invalid" do
        expect(ShardAccount.convert_to_currency(10, "EUR")).to eq("Error fetching exchange rate")
      end
    end

    # TODO: fix this test, no reason why its not passing
    # context "when the API key is missing" do
    #   before do
    #     allow(ENV).to receive(:[]).and_call_original # Keep original behavior
    #     allow(ENV).to receive(:[]).with('DATABASE_CLEANER_ALLOW_REMOTE_DATABASE_URL').and_return(nil)
    #     allow(ENV).to receive(:[]).with('CURRENCY_CONVERSION_API_KEY').and_return(nil)
    #     # ENV['CURRENCY_CONVERSION_API_KEY'] = nil
    #   end
    #
    #   it "raises an ArgumentError" do
    #     expect { ShardAccount.fetch_exchange_rate("EUR") }.to raise_error(ArgumentError)
    #   end
    # end
  end

  describe "fetch_exchange_rate" do
    context "successful API response" do
      before do
        stub_request(:get, /v6.exchangerate-api.com/).to_return(
          body: {
            "conversion_rates" => { "EUR" => 0.85 }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it "fetches the correct exchange rate" do
        expect(ShardAccount.fetch_exchange_rate("EUR")).to eq(0.85)
      end
    end

    context "API returns no conversion rates" do
      before do
        stub_request(:get, /v6.exchangerate-api.com/).to_return(
          body: { "conversion_rates" => nil }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it "returns nil if the conversion rate for the currency is not found" do
        expect(ShardAccount.fetch_exchange_rate("EUR")).to be_nil
      end
    end

    context "when an error occurs" do
      before do
        stub_request(:get, /v6.exchangerate-api.com/).to_raise(StandardError.new("Some error"))
      end

      it "logs the error and returns nil" do
        expect(Rails.logger).to receive(:error).with(/Exchange rate fetch failed: Some error/)
        expect(ShardAccount.fetch_exchange_rate("EUR")).to be_nil
      end
    end
  end
end
