@api
Feature: Host failover and timeouts

  Background:
    * call read('classpath:common/reset.feature')
    * url baseUrl
    * path '/v1/transactions'

  Scenario: Primary host down, fallback approves
    * call read('classpath:common/set-host.feature') { host: 'host-a', status: 'down' }
    Given request txn()
    When method post
    Then status 201
    And match response contains { status: 'APPROVED', host_id: 'host-c' }
    And match response.attempts[0] == { host: 'host-a', result: 'unavailable' }

  Scenario: Primary host times out, switch reverses there before failing over
    * call read('classpath:common/set-host.feature') { host: 'host-a', status: 'timeout' }
    Given request txn()
    When method post
    Then match response.host_id == 'host-c'
    And match response.attempts[0] == { host: 'host-a', result: 'timeout', reversal_sent: true }

  Scenario: Primary and fallback both unavailable
    * call read('classpath:common/set-host.feature') { host: 'host-a', status: 'down' }
    * call read('classpath:common/set-host.feature') { host: 'host-c', status: 'timeout' }
    Given request txn()
    When method post
    Then match response contains { status: 'DECLINED', response_code: '91', host_id: null }
    And match response.attempts[*].result == ['unavailable', 'timeout']

  Scenario: Route without a fallback fails after one attempt
    * call read('classpath:common/set-host.feature') { host: 'host-d', status: 'down' }
    Given request txn({ pan: '5061000000000000007' })
    When method post
    Then match response.response_code == '91'
    And match response.attempts == '#[1]'

  Scenario: Other routes are unaffected by a host outage
    * call read('classpath:common/set-host.feature') { host: 'host-a', status: 'down' }
    Given request txn({ pan: '5555555555554444' })
    When method post
    Then match response contains { host_id: 'host-b', response_code: '00' }
