class Card < ApplicationRecord
  belongs_to :shard_account

  validates :card_number_encrypted, presence: true
  validates :expiry_date, presence: true, format: { with: /\A(0[1-9]|1[0-2])\/\d{2}\z/, message: "must be in MM/YY format" }
  validates :cvv_encrypted, presence: true
  validates :billing_address, presence: true

  encrypts :card_number, :cvv

  validate :expiry_date_not_in_the_past

  private

  def expiry_date_not_in_the_past
    if expiry_date.present?
      begin
        parsed_date = Date.strptime(expiry_date, '%m/%y')
        if parsed_date < Date.today
          errors.add(:expiry_date, "can't be in the past")
        end
      rescue ArgumentError
        errors.add(:expiry_date, "must be in MM/YY format")
      end
    end
  end
end

