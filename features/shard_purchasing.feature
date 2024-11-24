# features/shop_functionality.rb

Feature: Shard Purchasing Interface
  As a user
  I want to interact with the shard purchasing page
  So that I can add shards to my balance

  Background:
    Given a "Mystery Box" item exists
    Given I am logged in as a user with a shard balance of 50 shards

  Scenario: User views the shard purchasing page
    Given I am on the shard purchasing page
    Then I should see a button with text "Return to Shop"
    And I should see "Shard Balance: 50 Shards"
    And I should see "Enter Amount of Shards:"
    And I should see a currency dropdown with options "USD, EUR, GBP, JPY, CAD, AUD"
    And I should see a button with text "Convert"
    And I should see a button with text "Buy"


  Scenario: User clicks "Return to Shop"
    Given I am on the shard purchasing page
    When I click the "Return to Shop" button
    Then I should be redirected to the shop page

  Scenario: User converts shard amount to selected currency
    Given I am on the shard purchasing page
    And I enter "10" into the "Enter Amount of Shards" field
    And I select "EUR" from the "Select Currency" dropdown
    When I click the "Convert" button
    Then I should see a conversion result displayed

#  Scenario: User tries to buy shards without entering an amount
#    Given I am on the shard purchasing page
#    When I click the "Buy" button
#    Then I should see an error message saying "Please enter a valid shard amount"
#
#
#  Scenario: User buys shards successfully
#    Given I am on the shard purchasing page
#    And I enter "10" into the "Enter Amount of Shards" field
#    And I select "USD" from the "Select Currency" dropdown
#    When I click the "Buy" button
#    Then I should see a confirmation message saying "Are you sure you want to buy 10 Shards"
#    And my shard balance should be updated to "60 Shards"

#  @javascript
#  Scenario: User sees an error message for invalid shard amount
#    Given I am on the shard purchasing page
#    When I click the "Buy" button
#    Then I should see a popup message saying "Please enter a valid amount and perform the conversion first."
#
#  @javascript
#  Scenario: User successfully buys shards
#    Given I am on the shard purchasing page
#    When I enter "10" into the "Enter Amount of Shards" field
#    And I select "USD" from the "Select Currency" dropdown
#    And I click the "Convert" button
#    And I click the "Buy" button
#    Then I should see a popup message saying "Successfully purchased 10 Shards!"
#    And the shard balance should be updated to "60 Shards"





