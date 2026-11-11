@api
Feature: Authorization

  Background:
    * call read('classpath:common/reset.feature')
    * url baseUrl
    * path '/v1/transactions'
    * def schema = read('classpath:common/transaction-schema.json')

  Scenario: Approved purchase matches the response contract
    Given request txn()
    When method post
    Then status 201
    And match response == schema
    And match response contains { status: 'APPROVED', response_code: '00', host_id: 'host-a', duplicate: false }
    And match response.pan_masked == '411111******1111'
    And match response.attempts == [{ host: 'host-a', result: '00' }]

  Scenario: Clear PAN never appears in a response
    Given request txn()
    When method post
    Then status 201
    And match karate.toString(response) !contains '4111111111111111'

  Scenario Outline: BIN <pan> routes to <host>
    Given request txn({ pan: '<pan>' })
    When method post
    Then status 201
    And match response.host_id == '<host>'

    Examples:
      | pan                 | host   |
      | 4111111111111111    | host-a |
      | 5555555555554444    | host-b |
      | 2223000048400011    | host-b |
      | 5061000000000000007 | host-d |

  Scenario Outline: Purchase of <amount> gets response <code>
    Given request txn({ amount: <amount> })
    When method post
    Then status 201
    And match response.response_code == '<code>'
    And match response.status == '<status>'
    And match response == schema

    Examples:
      | amount | code | status   |
      | 10000  | 00   | APPROVED |
      | 10005  | 05   | DECLINED |
      | 10051  | 51   | DECLINED |
      | 10061  | 61   | DECLINED |
      | 10091  | 91   | DECLINED |

  Scenario: Refunds are not declined by test amounts
    Given request txn({ type: 'refund', amount: 10051 })
    When method post
    Then status 201
    And match response.response_code == '00'

  Scenario: Expired card is declined by the issuer
    Given request txn({ expiry: '2001' })
    When method post
    Then match response contains { response_code: '54', response_message: 'Expired card' }

  Scenario: Luhn failure is declined by the switch without contacting a host
    Given request txn({ pan: '4111111111111112' })
    When method post
    Then match response contains { response_code: '14', host_id: null, attempts: [] }

  Scenario: Unrouted BIN is declined with 92
    Given request txn({ pan: '6011000990139424' })
    When method post
    Then match response.response_code == '92'

  Scenario: Repeated terminal and STAN returns the original result
    * def body = txn()
    Given request body
    When method post
    Then status 201
    * def original = response

    Given path '/v1/transactions'
    And request karate.merge(body, { amount: 99999 })
    When method post
    Then status 200
    And match response.id == original.id
    And match response.amount == 10000
    And match response.duplicate == true

  Scenario Outline: Invalid <field> is rejected
    Given request txn({ <field>: <value> })
    When method post
    Then status 422
    And match response.detail[0].loc contains '<field>'

    Examples:
      | field       | value              |
      | pan         | '41111'            |
      | pan         | '4111x11111111111' |
      | expiry      | '2813'             |
      | amount      | 0                  |
      | stan        | '12345'            |
      | terminal_id | 'TERM01'           |
      | currency    | 'NGN'              |
      | type        | 'cashback'         |
