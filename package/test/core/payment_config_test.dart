import 'package:flutter_test/flutter_test.dart';
import 'package:payment_gateways/payment_gateways.dart';

void main() {
  group('PaymentConfig.validate', () {
    test('accepts test config with http://localhost backend', () {
      final config = PaymentConfig(
        environment: Environment.test,
        gateways: {
          'stripe': const GatewayConfig.stripe(
            publishableKey: 'pk_test_abc',
          ),
        },
        backendBaseUrl: Uri.parse('http://localhost:4000'),
      );
      expect(config.validate, returnsNormally);
    });

    test('rejects http:// backend in production', () {
      final config = PaymentConfig(
        environment: Environment.production,
        gateways: {
          'stripe': const GatewayConfig.stripe(
            publishableKey: 'pk_live_xyz',
          ),
        },
        backendBaseUrl: Uri.parse('http://api.example.com'),
      );
      expect(config.validate, throwsArgumentError);
    });

    test('rejects empty gateway map', () {
      final config = PaymentConfig(
        environment: Environment.test,
        gateways: const {},
        backendBaseUrl: Uri.parse('https://api.example.com'),
      );
      expect(config.validate, throwsArgumentError);
    });

    test('rejects mismatched map key vs gatewayId', () {
      final config = PaymentConfig(
        environment: Environment.test,
        gateways: {
          'paypal': const GatewayConfig.stripe(
            publishableKey: 'pk_test_abc',
          ),
        },
        backendBaseUrl: Uri.parse('https://api.example.com'),
      );
      expect(config.validate, throwsArgumentError);
    });
  });

  group('Per-gateway config validation', () {
    test('Stripe rejects secret key in client', () {
      const cfg = GatewayConfig.stripe(publishableKey: 'sk_live_OOPS');
      expect(cfg.validate, throwsArgumentError);
    });

    test('Paymob requires integration ids', () {
      const cfg =
          GatewayConfig.paymob(publicKey: 'pk_abc', integrationIds: {});
      expect(cfg.validate, throwsArgumentError);
    });

    test('PayTabs requires both profileId and serverKey', () {
      const cfg = GatewayConfig.payTabs(profileId: '', serverKey: '');
      expect(cfg.validate, throwsArgumentError);
    });

    test('Fawry requires merchantCode', () {
      const cfg = GatewayConfig.fawry(merchantCode: '');
      expect(cfg.validate, throwsArgumentError);
    });

    test('PayPal requires clientId', () {
      const cfg = GatewayConfig.payPal(clientId: '');
      expect(cfg.validate, throwsArgumentError);
    });

    test('Square requires applicationId and locationId', () {
      const cfg = GatewayConfig.square(applicationId: '', locationId: '');
      expect(cfg.validate, throwsArgumentError);
    });
  });
}
