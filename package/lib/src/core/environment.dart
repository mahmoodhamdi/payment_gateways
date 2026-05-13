/// The runtime environment a gateway is operating in.
///
/// `test` selects sandbox endpoints and may relax certain validations
/// (e.g. accepting test card numbers). `production` enforces strict
/// validation and routes to live payment infrastructure.
enum Environment {
  test,
  production;

  bool get isProduction => this == Environment.production;
  bool get isTest => this == Environment.test;
}
