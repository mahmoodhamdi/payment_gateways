import 'package:flutter_test/flutter_test.dart';
import 'package:payment_gateways/payment_gateways.dart';

void main() {
  group('PaymentResult sealed variants', () {
    test('success carries transaction info', () {
      const r = PaymentResult.success(
        transactionId: 'txn_abc',
        gatewayName: 'stripe',
        receiptUrl: 'https://stripe.com/r/123',
      );
      expect(r, isA<PaymentSuccess>());
      r as PaymentSuccess;
      expect(r.transactionId, 'txn_abc');
      expect(r.gatewayName, 'stripe');
    });

    test('failure carries typed error', () {
      const r = PaymentResult.failure(error: InsufficientFundsError());
      expect(r, isA<PaymentFailure>());
      r as PaymentFailure;
      expect(r.error, isA<InsufficientFundsError>());
      expect(r.error.code, 'insufficient_funds');
    });

    test('canceled is a singleton-equal value', () {
      expect(
        const PaymentResult.canceled(),
        equals(const PaymentResult.canceled()),
      );
    });

    test('pendingAction defaults to 3DS', () {
      final r = PaymentResult.pendingAction(
        actionUrl: Uri.parse('https://stripe.com/3ds/abc'),
      );
      expect(r, isA<PaymentPendingAction>());
      r as PaymentPendingAction;
      expect(r.type, PendingActionType.threeDSecure);
    });

    test('exhaustive switch over the sealed PaymentResult', () {
      String describe(PaymentResult r) => switch (r) {
            PaymentSuccess() => 'success',
            PaymentFailure() => 'failure',
            PaymentCanceled() => 'canceled',
            PaymentPendingAction() => 'pending',
          };

      expect(
        describe(const PaymentResult.success(transactionId: 'x')),
        'success',
      );
      expect(
        describe(const PaymentResult.failure(error: ExpiredCardError())),
        'failure',
      );
      expect(describe(const PaymentResult.canceled()), 'canceled');
      expect(
        describe(
          PaymentResult.pendingAction(actionUrl: Uri.parse('https://x')),
        ),
        'pending',
      );
    });
  });

  group('PaymentError variants', () {
    test('each error has a code and a user message', () {
      const errors = <PaymentError>[
        InsufficientFundsError(),
        CardDeclinedError(),
        ExpiredCardError(),
        InvalidCvvError(),
        ThreeDSecureFailedError(),
        NetworkError(),
        GatewayUnavailableError(gateway: 'stripe'),
        ConfigError(details: 'oops'),
        UnknownError(),
      ];
      for (final e in errors) {
        expect(e.code.isNotEmpty, true, reason: 'empty code on ${e.runtimeType}');
        expect(
          e.userMessage.isNotEmpty,
          true,
          reason: 'empty userMessage on ${e.runtimeType}',
        );
      }
    });

    test('codes are unique', () {
      const errors = <PaymentError>[
        InsufficientFundsError(),
        CardDeclinedError(),
        ExpiredCardError(),
        InvalidCvvError(),
        ThreeDSecureFailedError(),
        NetworkError(),
        GatewayUnavailableError(gateway: 'stripe'),
        ConfigError(details: 'oops'),
        UnknownError(),
      ];
      final codes = errors.map((e) => e.code).toSet();
      expect(codes.length, errors.length);
    });
  });
}
