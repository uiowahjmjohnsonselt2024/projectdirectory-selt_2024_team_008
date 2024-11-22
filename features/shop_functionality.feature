Feature: Shop Interface
  As a user
  I want to interact with the shop interface
  So that I can view my shard balance, return to the menu, add funds, and access mystery boxes

  Background:
    Given I am logged in as a user with a shard balance of 50 shards

  Scenario: User views the shop interface
    Given I am on the shop page
    Then I should see a button with text "Return to Menu"
    And I should see "Shard Balance: 50 Shards"
    And I should see a button with text "Add Funds"
    And I should see a button with text "Go Here For Mystery Boxes"

  Scenario: User navigates back to the menu
    Given I am on the shop page
    When I click the "Return to Menu" button
    Then I should be redirected to the menu page

  Scenario: User navigates to add funds
    Given I am on the shop page
    When I click the "Add Funds" button
    Then I should be redirected to the buy shards page

  Scenario: User navigates to mystery boxes
    Given I am on the shop page
    When I click the "Go Here For Mystery Boxes" button
    Then I should be redirected to the mystery boxes page
