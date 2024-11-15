
Feature: User Authentication
  Scenario: User logs in with valid credentials
    Given a user with email "test@example.com" and password "password" exists
    When I go to the login page
    And I fill in "Email or Username" with "test@example.com"
    And I fill in "Password" with "password"
    And I press "Log in"
    Then I should see "Signed in successfully"

  Scenario: User fails to log in when using invalid credentials
    Given a user with email "test@example.com" and password "password" exists
    When I go to the login page
    And I fill in "Email or Username" with "test@example.com"
    And I fill in "Password" with "wrongpassword"
    And I press "Log in"
    Then I should see "Invalid Login or password"

  Scenario: User fails to log in when missing credentials
    Given a user with email "test@example.com" and password "password" exists
    When I go to the login page
    And I fill in "Email or Username" with "test@example.com"
    And I fill in "Password" with ""
    And I press "Log in"
    Then I should see "Invalid Login or password"
