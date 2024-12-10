Feature: Welcome Screen
  Scenario: User is on the welcome screen
    When I go to the welcome page
    Then I should see "Shards of the Grid"
  Scenario: User click login
    When I go to the welcome page
    And I press "Login"
    Then I should be redirected to the login page