Feature: Leaderboard page displays users sorted by their balance

  Background:
    Given I am logged in as a user with a shard balance of 50 shards

  Scenario: Viewing the leaderboard
    Given there are multiple users with different balances
    When I visit the leaderboard page
    Then I should see a list of users with their balances
    And the users should be sorted by balance in descending order

  Scenario: The leaderboard shows a maximum of 10 users
    Given there are more than 10 users
    When I visit the leaderboard page
    Then I should see no more than 10 users listed on the page
