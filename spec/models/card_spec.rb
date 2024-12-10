require 'rails_helper'

RSpec.describe Card, type: :model do
  let(:shard_account) { create(:shard_account) }

  let(:valid_card) do
    described_class.new(
      card_number_encrypted: 'encrypted_card_number',
      expiry_date: '12/25',
      cvv_encrypted: 'encrypted_cvv',
      billing_address: '123 Main St',
      shard_account: shard_account
    )
  end

  context 'validations' do
    it 'is valid with valid attributes' do
      expect(valid_card).to be_valid
    end

    it 'is not valid without a card number' do
      valid_card.card_number_encrypted = nil
      expect(valid_card).to_not be_valid
      expect(valid_card.errors[:card_number_encrypted]).to include("can't be blank")
    end

    it 'is not valid without an expiry date' do
      valid_card.expiry_date = nil
      expect(valid_card).to_not be_valid
      expect(valid_card.errors[:expiry_date]).to include("can't be blank")
    end

    it 'is not valid with an invalid expiry date format' do
      valid_card.expiry_date = '25/12'
      expect(valid_card).to_not be_valid
      expect(valid_card.errors[:expiry_date]).to include("must be in MM/YY format")
    end

    it 'is not valid with an expired expiry date' do
      valid_card.expiry_date = '01/21' # assuming this is a past date
      expect(valid_card).to_not be_valid
      expect(valid_card.errors[:expiry_date]).to include("can't be in the past")
    end

    it 'is not valid without a CVV' do
      valid_card.cvv_encrypted = nil
      expect(valid_card).to_not be_valid
      expect(valid_card.errors[:cvv_encrypted]).to include("can't be blank")
    end

    it 'is not valid without a billing address' do
      valid_card.billing_address = nil
      expect(valid_card).to_not be_valid
      expect(valid_card.errors[:billing_address]).to include("can't be blank")
    end
  end

  context 'encryption' do
    it 'encrypts the card number' do
      expect(valid_card.card_number).to_not eq('encrypted_card_number')
    end

    it 'encrypts the CVV' do
      expect(valid_card.cvv).to_not eq('encrypted_cvv')
    end
  end
end
