class ShopController < ApplicationController
  def index
    @shop_items = ShopItem.all
  end

  def show
    @shop_item = ShopItem.find(params[:id])
  end
end
