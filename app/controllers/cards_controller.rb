class CardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shard_account_cards

  def new
    @card = @shard_account.build_card
  end

  def create
    @card = @shard_account.build_card(card_params)
    if @card.save
      Rails.logger.debug "Card saved successfully. Redirecting to Add Funds."
      flash[:success] = "Card successfully saved."
      redirect_to buy_shards_shard_accounts_path
    else
      Rails.logger.debug "Card save failed: #{@card.errors.full_messages}"
      flash.now[:error] = "There was an error saving your card. Please try again."
      render :new
    end
  end

  private

  def set_shard_account_cards
    @shard_account = current_user.shard_account
    unless @shard_account
      redirect_to shop_index_path, alert: "Please create a Shard Account first."
    end
  end

  def card_params
    params.require(:card).permit(:card_number_encrypted, :expiry_date, :cvv_encrypted, :billing_address)
  end
end
