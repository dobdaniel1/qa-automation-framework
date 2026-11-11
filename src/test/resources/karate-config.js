function fn() {
  var baseUrl = karate.properties['baseUrl'] || karate.env || 'http://localhost:8000';
  var expiry = java.time.LocalDate.now().plusYears(2).format(java.time.format.DateTimeFormatter.ofPattern('yyMM'));

  function stan() {
    return ('000000' + Math.floor(Math.random() * 1000000)).slice(-6);
  }

  function txn(overrides) {
    var base = {
      type: 'purchase', pan: '4111111111111111', expiry: expiry, amount: 10000, currency: '566',
      stan: stan(), terminal_id: 'TERM0001', merchant_id: 'MERCHANT0000001'
    };
    return karate.merge(base, overrides || {});
  }

  karate.configure('connectTimeout', 5000);
  karate.configure('readTimeout', 10000);
  return { baseUrl: baseUrl, txn: txn, stan: stan, expiry: expiry };
}
