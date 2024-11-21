class ShardAccountsController < ApplicationController
  before_action :set_shard_account, only: [:show, :edit, :update, :destroy]

  def new_add_funds
    # This action renders the form for adding funds
  end


  before_action :authenticate_user!
  def convert_currency
    amount = params[:amount].to_i
    currency = params[:currency]

    # Rails.logger.info("Amount: #{amount}, Currency: #{currency}")

    if amount.positive? && currency.present?
      converted_amount = ShardAccount.convert_to_currency(amount, currency)
      # Rails.logger.info("Converted Amount: #{converted_amount}")
      render json: { converted_amount: converted_amount }, status: :ok
    else
      # Rails.logger.error("Invalid parameters: Amount=#{amount}, Currency=#{currency}")
      render json: { error: 'Invalid input' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    # Rails.logger.error("Error in convert_currency: #{e.message}")
    render json: { error: e.message }, status: :internal_server_error
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

  def convert
    shards = params[:shards].to_i
    target_currency = params[:currency]

    if shards <= 0 || target_currency.blank?
      render json: { error: 'Invalid input' }, status: :unprocessable_entity
      return
    end

    if target_currency != "USD"
      exchange_rate = fetch_exchange_rate(target_currency)
    else
      exchange_rate = 1
    end
    if exchange_rate.nil?
      render json: { error: 'Unable to fetch exchange rate' }, status: :service_unavailable
      return
    end

    shard_to_usd = 1 / 0.75
    cost_in_usd = shards * shard_to_usd
    calculated_value = (cost_in_usd * exchange_rate).ceil

    render json: { calculated_value: calculated_value }
  end

  def buy_item
    item = ShopItem.find(params[:item_id])
    if current_user.shard_account.balance >= item.price_in_shards
      current_user.shard_account.balance -= item.price_in_shards
      current_user.shard_account.save
      # TODO: Add item to user
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