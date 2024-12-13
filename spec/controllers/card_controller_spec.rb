# spec/controllers/cards_controller_spec.rb
require 'rails_helper'

RSpec.describe CardsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:shard_account) { create(:shard_account, user: user) }
  let(:valid_card_params) do
    { card_number_encrypted: '1234567812345678', expiry_date: '12/25', cvv_encrypted: '123', billing_address: '100 main st' }
  end

  before do
    sign_in user
    allow(user).to receive(:shard_account).and_return(shard_account)
  end

  describe "GET #new" do
    it "assigns a new card to @card and renders the new template" do
      get :new
      expect(assigns(:card)).to be_a_new(Card)
      expect(response).to render_template(:new)
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new card and redirects to the buy_shards_shard_accounts_path" do
        expect {
          post :create, params: { card: valid_card_params }
        }.to change(Card, :count).by(1)

        expect(flash[:success]).to eq("Card successfully saved.")
        expect(response).to redirect_to(buy_shards_shard_accounts_path)
      end
    end

    context "with invalid parameters" do
      it "does not save the card and re-renders the new template" do
        invalid_params = { card_number_encrypted: '', expiry_date: '12/25', cvv_encrypted: '123', billing_address: '100 main st' }

        post :create, params: { card: invalid_params }

        expect(assigns(:card)).not_to be_persisted
        expect(flash.now[:error]).to eq("There was an error saving your card. Please try again.")
        expect(response).to render_template(:new)
      end
    end
  end

end
