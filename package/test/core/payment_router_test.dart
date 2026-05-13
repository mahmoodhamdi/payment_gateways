import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payment_gateways/payment_gateways.dart';

void main() {
  final stripe = _FakeGateway(
    id: 'stripe',
    supports: const {'card', 'wallet'},
    currencies: {Currency.usd, Currency.eur, Currency.gbp},
    regions: {}, // any
  );
  final paymob = _FakeGateway(
    id: 'paymob',
    supports: const {'card', 'wallet'},
    currencies: {Currency.egp},
    regions: {Region.eg},
  );
  final paytabs = _FakeGateway(
    id: 'paytabs',
    supports: const {'card'},
    currencies: {Currency.sar, Currency.aed, Currency.kwd},
    regions: {Region.sa, Region.ae, Region.kw},
  );
  final fawry = _FakeGateway(
    id: 'fawry',
    supports: const {'cash'},
    currencies: {Currency.egp},
    regions: {Region.eg},
  );

  group('byCountry routing', () {
    test('Egyptian customer paying card EGP → Paymob (MENA preference)', () {
      final router = PaymentRouter(
        rules: const RoutingRules.byCountry(),
        gateways: [stripe, paymob, paytabs, fawry],
      );
      final chosen = router.select(
        method: const PaymentMethod.card(),
        currency: Currency.egp,
        customerCountry: Region.eg,
      );
      expect(chosen.id, 'paymob');
    });

    test('Saudi customer paying card SAR → PayTabs', () {
      final router = PaymentRouter(
        rules: const RoutingRules.byCountry(),
        gateways: [stripe, paymob, paytabs, fawry],
      );
      final chosen = router.select(
        method: const PaymentMethod.card(),
        currency: Currency.sar,
        customerCountry: Region.sa,
      );
      expect(chosen.id, 'paytabs');
    });

    test('US customer paying card USD → Stripe', () {
      final router = PaymentRouter(
        rules: const RoutingRules.byCountry(),
        gateways: [stripe, paymob, paytabs, fawry],
      );
      final chosen = router.select(
        method: const PaymentMethod.card(),
        currency: Currency.usd,
        customerCountry: Region.us,
      );
      expect(chosen.id, 'stripe');
    });

    test('Egyptian customer paying cash → Fawry', () {
      final router = PaymentRouter(
        rules: const RoutingRules.byCountry(),
        gateways: [stripe, paymob, paytabs, fawry],
      );
      final chosen = router.select(
        method: const PaymentMethod.cash(type: CashType.fawryOutlet),
        currency: Currency.egp,
        customerCountry: Region.eg,
      );
      expect(chosen.id, 'fawry');
    });

    test('no fit throws GatewayUnavailableError', () {
      final router = PaymentRouter(
        rules: const RoutingRules.byCountry(),
        gateways: [fawry], // cash-only
      );
      expect(
        () => router.select(
          method: const PaymentMethod.card(),
          currency: Currency.usd,
          customerCountry: Region.us,
        ),
        throwsA(isA<GatewayUnavailableError>()),
      );
    });
  });

  group('fixed routing', () {
    test('always returns the pinned gateway when present', () {
      final router = PaymentRouter(
        rules: const RoutingRules.fixed('paymob'),
        gateways: [stripe, paymob, paytabs],
      );
      final chosen = router.select(
        method: const PaymentMethod.card(),
        currency: Currency.usd, // Paymob doesn't actually support USD
        customerCountry: Region.us,
      );
      expect(chosen.id, 'paymob');
    });

    test('throws when pinned gateway not registered', () {
      final router = PaymentRouter(
        rules: const RoutingRules.fixed('nope'),
        gateways: [stripe],
      );
      expect(
        () => router.select(
          method: const PaymentMethod.card(),
          currency: Currency.usd,
          customerCountry: null,
        ),
        throwsA(isA<GatewayUnavailableError>()),
      );
    });
  });

  group('custom routing', () {
    test('callable selector is invoked', () {
      final router = PaymentRouter(
        rules: RoutingRules.custom(
          ({
            required available,
            required currency,
            required customerCountry,
            required method,
          }) {
            return available.firstWhere((g) => g.id == 'paytabs');
          },
        ),
        gateways: [stripe, paytabs],
      );
      final chosen = router.select(
        method: const PaymentMethod.card(),
        currency: Currency.usd,
        customerCountry: null,
      );
      expect(chosen.id, 'paytabs');
    });
  });
}

class _FakeGateway implements PaymentGateway {
  _FakeGateway({
    required this.id,
    required Set<String> supports,
    required Set<Currency> currencies,
    required Set<Region> regions,
  })  : _supportedKinds = supports,
        metadata = GatewayMetadata(
          id: id,
          displayName: id,
          supportedCurrencies: currencies,
          supportedRegions: regions,
        );

  @override
  final String id;
  final Set<String> _supportedKinds;
  @override
  final GatewayMetadata metadata;

  @override
  bool supports(PaymentMethod method) =>
      _supportedKinds.contains(method.kind);

  @override
  Future<PaymentResult> initiate({
    required PaymentIntent intent,
    required PaymentMethod method,
    required BuildContext context,
  }) async {
    return const PaymentResult.success(transactionId: 'fake-success');
  }

  @override
  Future<PaymentResult> refund({
    required String transactionId,
    int? amountMinorUnits,
  }) async {
    return PaymentResult.success(transactionId: transactionId);
  }

  @override
  Future<PaymentStatus> getStatus({required String transactionId}) async {
    return PaymentStatus.succeeded;
  }
}
