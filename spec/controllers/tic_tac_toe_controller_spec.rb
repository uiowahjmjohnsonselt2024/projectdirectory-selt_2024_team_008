require 'rails_helper'

RSpec.describe TicTacToeController, type: :controller do
  include Devise::Test::ControllerHelpers

  let!(:user) do
    user = User.create!(username: 'test_user', email: 'test@example.com', password: 'password')
    ShardAccount.create!(user: user, balance: 0) # Initialize with 0 shards
    user
  end

  let(:shard_account) { user.shard_account }
  before do
    sign_in user
    allow(controller).to receive(:current_user).and_return(user)
    allow(user).to receive(:shard_account).and_return(shard_account)
  end
end