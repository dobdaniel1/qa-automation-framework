@api
Feature: Reversals

  Background:
    * call read('classpath:common/reset.feature')
    * url baseUrl
    * def approved = call read('classpath:common/send.feature') { body: '#(txn())' }
    * def id = approved.response.id

  Scenario: Approved transaction is reversed
    Given path '/v1/transactions', id, 'reversal'
    When method post
    Then status 200
    And match response.status == 'REVERSED'
    And match response.reversed_at == '#string'

  Scenario: Reversal is idempotent
    Given path '/v1/transactions', id, 'reversal'
    When method post
    Then status 200
    * def first = response
    Given path '/v1/transactions', id, 'reversal'
    When method post
    Then status 200
    And match response == first

  Scenario: Declined transaction cannot be reversed
    * def declined = call read('classpath:common/send.feature') { body: '#(txn({ amount: 10051 }))' }
    Given path '/v1/transactions', declined.response.id, 'reversal'
    When method post
    Then status 409

  Scenario: Unknown transaction returns 404
    Given path '/v1/transactions', 'does-not-exist', 'reversal'
    When method post
    Then status 404

  Scenario: Reversal is queued while the host is down and delivered when it returns
    * call read('classpath:common/set-host.feature') { host: 'host-a', status: 'down' }
    Given path '/v1/transactions', id, 'reversal'
    When method post
    Then match response.status == 'REVERSAL_PENDING'

    Given path '/v1/reversals/retry'
    When method post
    Then match response == { delivered: [], still_pending: ['#(id)'] }

    * call read('classpath:common/set-host.feature') { host: 'host-a', status: 'up' }
    Given path '/v1/reversals/retry'
    When method post
    Then match response == { delivered: ['#(id)'], still_pending: [] }

    Given path '/v1/transactions', id
    When method get
    Then match response.status == 'REVERSED'
