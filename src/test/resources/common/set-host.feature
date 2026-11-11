@ignore
Feature: Set a host status. Call with { host: 'host-a', status: 'down' }

  Scenario:
    Given url baseUrl
    And path '/v1/hosts', host
    And request { status: '#(status)' }
    When method patch
    Then status 200
    And match response.status == status
