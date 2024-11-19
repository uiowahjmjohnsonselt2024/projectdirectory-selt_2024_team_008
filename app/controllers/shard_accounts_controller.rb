class ShardAccountsController < ApplicationController
  before_action :set_shard_account, only: [:show, :edit, :update, :destroy]

  def new_add_funds
    # This action renders the form for adding funds
  end

  def add_funds
    currency = params[:currency]
    deposit_amount = params[:amount].to_i
    card_number = params[:card_number]
    expiry_date = params[:expiry_date]
    cvv = params[:cvv]
    if valid_card?(card_number, expiry_date, cvv)
      shards = ShardAccount.usd_to_shards(deposit_amount)
      shard_account = current_user.shard_account
      shard_account.balance += shards
      if shard_account.save
        flash[:success] = "Successfully added #{shards} shards to your account."
      else
        flash[:error] = "Failed to add shards to your account."
      end
      redirect_to shop_index_path
    else
      flash[:error] = "Card is not valid. Please try again."
    end

  end

  def buy_item
    item = ShopItem.find(params[:item_id])
    if @shard_account.balance >= item.price_in_shards
      @shard_account.balance -= item.price_in_shards
      @shard_account.save
      flash[:success] = "You purchased #{item.name}!"
    else
      flash[:error] = "Insufficient Shards."
    end
    redirect_to shop_index_path
  end

  def set_shard_account
    @shard_account = current_user.shard_account
  end

  def valid_card?(card_number, expiry_date, cvv)
    # Simple validation for mock purposes
    card_number.match?(/\A\d{16}\z/) &&
      expiry_date.match?(/\A(0[1-9]|1[0-2])\/\d{2}\z/) &&
      cvv.match?(/\A\d{3}\z/)
  end
end