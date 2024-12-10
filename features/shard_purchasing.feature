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
    And I have a valid payment method
    And I should see a currency dropdown with options "USD, EUR, GBP, JPY, CAD, AUD"
    And I should see a button with text "Convert"

  Scenario: User is prompted to add a payment method if one is not present
    Given I am on the shard purchasing page
    And I do not have a saved payment method
    Then I should see "Add Payment Method"

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

  Scenario: User converts shard amount to selected currency
    Given I am on the shard purchasing page
    And I enter "10" into the "Enter Amount of Shards" field
    And I select "EUR" from the "Select Currency" dropdown
    When I click the "Convert" button
    Then I should see a conversion result displayed


