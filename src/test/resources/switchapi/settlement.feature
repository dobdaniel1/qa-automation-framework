@api
Feature: Settlement and reconciliation

  Background:
    * call read('classpath:common/reset.feature')
    * url baseUrl
    * def send = function(o) { return karate.call('classpath:common/send.feature', { body: txn(o) }).response }

  Scenario: Batch totals exclude declined and reversed transactions
    * send({ amount: 10000 })
    * send({ amount: 2500 })
    * send({ type: 'refund', amount: 1500 })
    * send({ amount: 10051 })
    * def toReverse = send({ amount: 7000 })
    Given path '/v1/transactions', toReverse.id, 'reversal'
    When method post
    Then status 200

    Given path '/v1/settlement/batches'
    And request {}
    When method post
    Then status 201
    And match response.transaction_count == 3
    And match response.totals == { '566': { purchase: 12500, refund: 1500, net: 11000 } }

  Scenario: Closing an empty batch is rejected
    Given path '/v1/settlement/batches'
    And request {}
    When method post
    Then status 409

  Scenario: Settled transactions cannot be reversed
    * def t = send({})
    Given path '/v1/settlement/batches'
    And request {}
    When method post
    Then status 201
    Given path '/v1/transactions', t.id, 'reversal'
    When method post
    Then status 409

  Scenario: Host file identical to the switch file reconciles cleanly
    * send({ amount: 1000 })
    * send({ amount: 2000 })
    Given path '/v1/settlement/batches'
    And request {}
    When method post
    * def batchId = response.id

    Given path '/v1/settlement/batches', batchId, 'file'
    When method get
    Then status 200
    * def file = response

    Given path '/v1/settlement/batches', batchId, 'reconcile'
    And header Content-Type = 'text/csv'
    And request file
    When method post
    Then status 200
    And match response.balanced == true
    And match response.matched == '#[2]'

  Scenario: Reconciliation reports every type of break
    * def a = send({ amount: 1000 })
    * def b = send({ amount: 2000 })
    * def c = send({ amount: 3000 })
    Given path '/v1/settlement/batches'
    And request {}
    When method post
    * def batchId = response.id
    * def hostFile = 'rrn,amount\n' + a.rrn + ',1000\n' + b.rrn + ',2001\n' + b.rrn + ',2001\n' + '999999999999,500\n'

    Given path '/v1/settlement/batches', batchId, 'reconcile'
    And header Content-Type = 'text/csv'
    And request hostFile
    When method post
    Then status 200
    And match response.balanced == false
    And match response.matched == [ '#(a.rrn)' ]
    And match response.amount_mismatch == [{ rrn: '#(b.rrn)', switch_amount: 2000, host_amount: 2001 }]
    And match response.missing_in_host == [ '#(c.rrn)' ]
    And match response.missing_in_switch == ['999999999999']
    And match response.duplicates_in_host == [ '#(b.rrn)' ]
