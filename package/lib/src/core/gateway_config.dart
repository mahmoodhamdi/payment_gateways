/// Per-gateway configuration. Only public-key-class material here — secret
/// keys live in the backend companion.
sealed class GatewayConfig {
  const GatewayConfig();

  /// Stable gateway id this config targets (`"stripe"`, `"paymob"`, ...).
  String get gatewayId;

  /// Validates the config; throws [ArgumentError] if invalid.
  void validate();

  // ---- Convenience constructors -----------------------------------------

  const factory GatewayConfig.stripe({
    required String publishableKey,
    String? merchantIdentifier,
  }) = StripeConfig;

  const factory GatewayConfig.paymob({
    required String publicKey,
    required Map<String, int> integrationIds,
    String? iframeId,
  }) = PaymobConfig;

  const factory GatewayConfig.payTabs({
    required String profileId,
    required String serverKey,
    String? region,
  }) = PayTabsConfig;

  const factory GatewayConfig.fawry({
    required String merchantCode,
    bool useStaging,
  }) = FawryConfig;

  const factory GatewayConfig.payPal({
    required String clientId,
  }) = PayPalConfig;

  const factory GatewayConfig.square({
    required String applicationId,
    required String locationId,
  }) = SquareConfig;
}

final class StripeConfig extends GatewayConfig {
  const StripeConfig({
    required this.publishableKey,
    this.merchantIdentifier,
  });

  final String publishableKey;

  /// Apple Pay merchant identifier (`merchant.com.your-app`).
  final String? merchantIdentifier;

  @override
  String get gatewayId => 'stripe';

  @override
  void validate() {
    if (!publishableKey.startsWith('pk_')) {
      throw ArgumentError(
        'Stripe publishableKey must start with "pk_". '
        'You may have pasted a secret key (`sk_...`) — this is unsafe in a '
        'client and will be rejected.',
      );
    }
  }
}

final class PaymobConfig extends GatewayConfig {
  const PaymobConfig({
    required this.publicKey,
    required this.integrationIds,
    this.iframeId,
  });

  /// Paymob public key (only used by client SDKs — auth_token / hmac live
  /// server-side).
  final String publicKey;

  /// Map of method → integration id. Required keys depend on which methods
  /// you accept (`"card"`, `"mobile_wallet"`, `"kiosk"`).
  final Map<String, int> integrationIds;

  /// Paymob iframe id (used when redirecting card flows to the hosted form).
  final String? iframeId;

  @override
  String get gatewayId => 'paymob';

  @override
  void validate() {
    if (publicKey.isEmpty) {
      throw ArgumentError('Paymob publicKey is required.');
    }
    if (integrationIds.isEmpty) {
      throw ArgumentError(
        'Paymob requires at least one integration id (e.g. "card").',
      );
    }
  }
}

final class PayTabsConfig extends GatewayConfig {
  const PayTabsConfig({
    required this.profileId,
    required this.serverKey,
    this.region,
  });

  final String profileId;
  final String serverKey;

  /// `ARE` / `SAU` / `KWT` / `OMN` / `JOR` / `EGY` / `GLOBAL` — the
  /// PayTabs region your account is provisioned for.
  final String? region;

  @override
  String get gatewayId => 'paytabs';

  @override
  void validate() {
    if (profileId.isEmpty || serverKey.isEmpty) {
      throw ArgumentError('PayTabs requires both profileId and serverKey.');
    }
  }
}

final class FawryConfig extends GatewayConfig {
  const FawryConfig({
    required this.merchantCode,
    this.useStaging = false,
  });

  final String merchantCode;
  final bool useStaging;

  @override
  String get gatewayId => 'fawry';

  @override
  void validate() {
    if (merchantCode.isEmpty) {
      throw ArgumentError('Fawry merchantCode is required.');
    }
  }
}

final class PayPalConfig extends GatewayConfig {
  const PayPalConfig({required this.clientId});
  final String clientId;

  @override
  String get gatewayId => 'paypal';

  @override
  void validate() {
    if (clientId.isEmpty) {
      throw ArgumentError('PayPal clientId is required.');
    }
  }
}

final class SquareConfig extends GatewayConfig {
  const SquareConfig({
    required this.applicationId,
    required this.locationId,
  });
  final String applicationId;
  final String locationId;

  @override
  String get gatewayId => 'square';

  @override
  void validate() {
    if (applicationId.isEmpty || locationId.isEmpty) {
      throw ArgumentError(
        'Square requires both applicationId and locationId.',
      );
    }
  }
}
