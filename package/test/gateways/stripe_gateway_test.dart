import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payment_gateways/payment_gateways.dart';

class _FakeBackend extends Mock implements BackendClient {}

void main() {
  late StripeGateway gateway;
  late _FakeBackend backend;

  setUp(() {
    backend = _FakeBackend();
    gateway = StripeGateway(
      config: const GatewayConfig.stripe(publishableKey: 'pk_test_abc')
          as StripeConfig,
      backend: backend,
      logger: PaymentLogger(),
    );
  });

  group('StripeGateway.supports', () {
    test('supports cards', () {
      expect(gateway.supports(const PaymentMethod.card()), true);
    });

    test('supports Apple Pay / Google Pay / Link', () {
      expect(
        gateway.supports(const PaymentMethod.wallet(type: WalletType.applePay)),
        true,
      );
      expect(
        gateway
            .supports(const PaymentMethod.wallet(type: WalletType.googlePay)),
        true,
      );
      expect(
        gateway.supports(const PaymentMethod.wallet(type: WalletType.link)),
        true,
      );
    });

    test('does not support Egyptian wallets', () {
      expect(
        gateway.supports(
          const PaymentMethod.wallet(type: WalletType.vodafoneCash),
        ),
        false,
      );
    });

    test('does not support cash', () {
      expect(
        gateway.supports(
          const PaymentMethod.cash(type: CashType.fawryOutlet),
        ),
        false,
      );
    });
  });

  group('StripeGateway metadata', () {
    test('includes USD, EUR, GBP', () {
      expect(gateway.metadata.supportedCurrencies.contains(Currency.usd), true);
      expect(gateway.metadata.supportedCurrencies.contains(Currency.eur), true);
      expect(gateway.metadata.supportedCurrencies.contains(Currency.gbp), true);
    });

    test('marked as global (empty regions)', () {
      expect(gateway.metadata.supportedRegions, isEmpty);
    });

    test('supports subscriptions natively', () {
      expect(gateway.metadata.supportsSubscriptionsNatively, true);
    });
  });

  group('StripeGateway.build factory', () {
    test('throws ConfigError on wrong config type', () {
      expect(
        () => StripeGateway.build(
          const GatewayConfig.paymob(publicKey: 'x', integrationIds: {'card': 1})
              as Object,
          backend,
          PaymentLogger(),
        ),
        throwsA(isA<ConfigError>()),
      );
    });
  });
}
