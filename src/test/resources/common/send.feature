@ignore
Feature: Send a transaction. Call with { body: ... }

  Scenario:
    Given url baseUrl
    And path '/v1/transactions'
    And request body
    When method post
    Then assert responseStatus == 200 || responseStatus == 201
