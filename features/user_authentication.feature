
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

  Scenario: User logs in with Google successfully
    Given OmniAuth is configured for Google
    And I visit the login page
    When I click "Sign in with Google"
    Then I should be redirected to the dashboard
    And I should see "Successfully authenticated from Google account."

  Scenario: User fails to log in with Google due to invalid credentials
    Given OmniAuth is configured with invalid credentials for Google
    And I visit the login page
    When I click "Sign in with Google"
    Then I should be redirected to the login page
    And I should see "Something went wrong. Please try again."

  Scenario: User tries to log in with Google but an account already exists with the same email
    Given a user with email "test@example.com" and password "password" exists
    And OmniAuth is configured for Google with email "test@example.com"
    And I visit the login page
    When I click "Sign in with Google"
    Then I should see "Email has already been taken"
    And I should be redirected to the sign up page
