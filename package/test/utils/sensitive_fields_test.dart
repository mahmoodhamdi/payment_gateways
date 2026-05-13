import 'package:flutter_test/flutter_test.dart';
import 'package:payment_gateways/payment_gateways.dart';

void main() {
  group('sensitive_fields', () {
    test('redact masks known sensitive keys', () {
      final masked = redact({
        'card_number': '4242 4242 4242 4242',
        'cvv': '123',
        'expiry': '12/29',
        'safe': 'hello',
      });
      expect(masked['card_number'], '***');
      expect(masked['cvv'], '***');
      expect(masked['expiry'], '***');
      expect(masked['safe'], 'hello');
    });

    test('redact recurses into nested maps', () {
      final masked = redact({
        'customer': {
          'email': 'a@b.com',
          'cvv': '999',
        },
      });
      final cust = masked['customer']! as Map<String, Object?>;
      expect(cust['email'], 'a@b.com');
      expect(cust['cvv'], '***');
    });

    test('redact recurses into maps inside lists', () {
      final masked = redact({
        'events': [
          {'pan': '4242', 'ok': 'fine'},
        ],
      });
      final events = masked['events']! as List<Object?>;
      final ev0 = events.first! as Map<String, Object?>;
      expect(ev0['pan'], '***');
      expect(ev0['ok'], 'fine');
    });

    test('redact is case-insensitive on keys', () {
      final masked = redact({'PAN': '1234', 'Cvv': '999'});
      expect(masked['PAN'], '***');
      expect(masked['Cvv'], '***');
    });

    test('maskValue keeps last 4 chars when value is long enough', () {
      expect(maskValue('4242424242424242'), '************4242');
      expect(maskValue('abc'), '***');
    });
  });
}
