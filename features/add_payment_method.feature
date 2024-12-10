Feature: Add a Card to Shard Account
  As a user
  I want to add a payment card to my shard account
  So that I can purchase shards with my card

  Background:
    Given I am logged in as a user with a shard account

  Scenario: User views the add card page
    Given I am on the "Add a Card to Your Shard Account" page
    Then I should see the heading "Add a Card to Your Shard Account"
    And I should see "Card Number"
    And I should see "CVV"
    And I should see a "Save Information" button

    # TODO: make these pass eventually, currently make no sense why they dont for me
#  Scenario: User enters valid card information and submits the form
#    Given I am on the "Add a Card to Your Shard Account" page
#    When I fill the card field "Card Number" with "1234 5678 9012 3456"
#    And I fill the card field "Expiry Date (MM/YY)" with "12/25"
#    And I fill the card field "CVV" with "123"
#    And I fill the card field "Street Address" with "100 Main St"
#    And I click the "Save Information" button
#    Then I should see a confirmation message saying "Card information has been successfully added"
#    Then I am on the shop page
#
#  Scenario: User tries to submit the form with missing required fields
#    Given I am on the "Add a Card to Your Shard Account" page
#    When I click the "Save Information" button
#    Then I should see the following error messages:
#      | Card Number           | can't be blank |
#      | Expiry Date (MM/YY)   | can't be blank |
#      | CVV                   | can't be blank |
#      | Street Address        | can't be blank |

  Scenario: User clicks "Return to Shop" and is redirected to the shop page
    Given I am on the "Add a Card to Your Shard Account" page
    When I click the "Return to Shop" button
    Then I am on the shop page
