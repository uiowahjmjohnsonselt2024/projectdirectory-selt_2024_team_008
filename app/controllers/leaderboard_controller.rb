class LeaderboardController < ApplicationController
  def index
    @users = User.joins(:shard_account)          # Join users with their shard_account
                 .order('shard_accounts.balance DESC')  # Order by shard_account balance in descending order
                 .limit(10)                       # Limit to top 10 users
  end
end
