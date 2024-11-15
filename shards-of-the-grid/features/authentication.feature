# features/authentication.feature
Feature: User Authentication

  Scenario: Viewing the login page
    Given I am a visitor
    When I navigate to the login page
    Then the login form is displayed

  Scenario: Successful login with valid credentials
    Given I am a registered user
    When I navigate to the login page
    And I submit my email and password
    Then I am logged in successfully
    And I am redirected to the home page

  Scenario: Unsuccessful login with invalid credentials
    Given I am a registered user
    When I navigate to the login page
    And I enter an incorrect password
    Then an error message is displayed
    And I remain on the login page

  Scenario: Logging out
    Given I am logged in as a registered user
    When I log out
    Then I am redirected to the home page
    And a logout confirmation message is displayed
