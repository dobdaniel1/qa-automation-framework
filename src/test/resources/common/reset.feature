@ignore
Feature: Reset switch data and host statuses

  Scenario:
    Given url baseUrl
    And path '/v1/admin/reset'
    When method post
    Then status 204
