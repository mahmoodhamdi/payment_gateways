import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payment_gateways/payment_gateways.dart';

class _FakeBackend extends Mock implements BackendClient {}

void main() {
  late FawryGateway gateway;

  setUp(() {
    gateway = FawryGateway(
      config: const GatewayConfig.fawry(merchantCode: 'M-12345') as FawryConfig,
      backend: _FakeBackend(),
      logger: PaymentLogger(),
    );
  });

  test('supports Fawry outlet and ATM cash methods', () {
    expect(
      gateway.supports(const PaymentMethod.cash(type: CashType.fawryOutlet)),
      true,
    );
    expect(
      gateway.supports(const PaymentMethod.cash(type: CashType.fawryAtm)),
      true,
    );
  });

  test('does not support cards', () {
    expect(gateway.supports(const PaymentMethod.card()), false);
  });

  test('does not support Aman outlet (Paymob territory)', () {
    expect(
      gateway.supports(const PaymentMethod.cash(type: CashType.amanOutlet)),
      false,
    );
  });

  test('metadata declares EGP / Egypt / cash', () {
    expect(gateway.metadata.supportedCurrencies, contains(Currency.egp));
    expect(gateway.metadata.supportedRegions, contains(Region.eg));
    expect(gateway.metadata.supportsCash, true);
    expect(gateway.metadata.supportsCards, false);
  });
}
