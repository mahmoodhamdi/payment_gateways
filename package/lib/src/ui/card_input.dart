import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payment_gateways/src/core/payment_method.dart';
import 'package:payment_gateways/src/ui/payment_gateways_theme.dart';

/// Raw card details captured by [CardInput]. The integrator must immediately
/// hand this off to a gateway adapter for tokenization — DO NOT log, persist,
/// or serialize this value.
@immutable
class RawCardDetails {
  const RawCardDetails({
    required this.numberDigitsOnly,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    this.cardholderName,
  });

  final String numberDigitsOnly;
  final int expiryMonth;
  final int expiryYear;
  final String cvv;
  final String? cardholderName;

  /// First 6 digits (BIN). Safe to keep for routing decisions.
  String get bin => numberDigitsOnly.substring(
        0,
        numberDigitsOnly.length >= 6 ? 6 : numberDigitsOnly.length,
      );

  /// Last 4 digits. Safe to display.
  String get last4 => numberDigitsOnly.substring(
        numberDigitsOnly.length - (numberDigitsOnly.length >= 4 ? 4 : 0),
      );
}

/// In-app card input field. Provided as a fallback for gateways without a
/// hosted iframe; production deployments should prefer Stripe Elements,
/// Paymob iframe, etc. for PCI scope reduction.
///
/// The widget never persists the captured raw values; the integrator's
/// [onSubmit] callback is expected to tokenize immediately.
class CardInput extends StatefulWidget {
  const CardInput({
    required this.onSubmit,
    super.key,
    this.submitButtonLabel,
    this.collectCardholderName = false,
  });

  final ValueChanged<RawCardDetails> onSubmit;
  final String? submitButtonLabel;
  final bool collectCardholderName;

  @override
  State<CardInput> createState() => _CardInputState();
}

class _CardInputState extends State<CardInput> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  CardBrand _brand = CardBrand.unknown;

  @override
  void dispose() {
    // Best-effort: clear sensitive state from memory before dispose.
    _numberCtrl
      ..text = ''
      ..dispose();
    _expiryCtrl
      ..text = ''
      ..dispose();
    _cvvCtrl
      ..text = ''
      ..dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PaymentGatewaysTheme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.collectCardholderName) ...[
            TextFormField(
              controller: _nameCtrl,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Cardholder name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            SizedBox(height: t.verticalGap),
          ],
          TextFormField(
            controller: _numberCtrl,
            keyboardType: TextInputType.number,
            autocorrect: false,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
              LengthLimitingTextInputFormatter(19), // 16 digits + 3 spaces
            ],
            decoration: InputDecoration(
              labelText: 'Card number',
              border: const OutlineInputBorder(),
              suffix: Text(_brand.name, style: t.captionText),
            ),
            onChanged: (v) {
              setState(() => _brand = _detectBrand(v));
            },
            validator: _validateCardNumber,
          ),
          SizedBox(height: t.verticalGap),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryCtrl,
                  keyboardType: TextInputType.number,
                  autocorrect: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryFormatter(),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'MM/YY',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateExpiry,
                ),
              ),
              SizedBox(width: t.horizontalPadding),
              Expanded(
                child: TextFormField(
                  controller: _cvvCtrl,
                  keyboardType: TextInputType.number,
                  autocorrect: false,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateCvv,
                ),
              ),
            ],
          ),
          SizedBox(height: t.verticalGap),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: t.primary,
              foregroundColor: t.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.cornerRadius),
              ),
            ),
            child: Text(widget.submitButtonLabel ?? 'Pay'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final exp = _expiryCtrl.text.split('/');
    widget.onSubmit(
      RawCardDetails(
        numberDigitsOnly: _numberCtrl.text.replaceAll(' ', ''),
        expiryMonth: int.parse(exp[0]),
        expiryYear: 2000 + int.parse(exp[1]),
        cvv: _cvvCtrl.text,
        cardholderName: widget.collectCardholderName ? _nameCtrl.text : null,
      ),
    );
  }

  String? _validateCardNumber(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final digits = v.replaceAll(' ', '');
    if (digits.length < 13 || digits.length > 19) return 'Invalid length';
    if (!_luhnValid(digits)) return 'Invalid card number';
    return null;
  }

  String? _validateExpiry(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v)) return 'Use MM/YY';
    final parts = v.split('/');
    final m = int.tryParse(parts[0]) ?? 0;
    final y = int.tryParse(parts[1]) ?? -1;
    if (m < 1 || m > 12) return 'Invalid month';
    if (y < 0) return 'Invalid year';
    // Expiry must be in the future or current month/year.
    final now = DateTime.now();
    final expiry = DateTime(2000 + y, m + 1);
    if (expiry.isBefore(now)) return 'Card expired';
    return null;
  }

  String? _validateCvv(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v.length < 3 || v.length > 4) return 'Invalid';
    return null;
  }

  static bool _luhnValid(String digits) {
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  static CardBrand _detectBrand(String input) {
    final digits = input.replaceAll(' ', '');
    if (digits.isEmpty) return CardBrand.unknown;
    if (digits.startsWith('4')) return CardBrand.visa;
    if (RegExp('^(5[1-5]|2[2-7])').hasMatch(digits)) {
      return CardBrand.mastercard;
    }
    if (digits.startsWith('3') &&
        digits.length > 1 &&
        (digits[1] == '4' || digits[1] == '7')) {
      return CardBrand.amex;
    }
    if (digits.startsWith('6')) return CardBrand.discover;
    // mada BIN ranges are extensive; this is a simplified detector.
    if (RegExp('^(440533|446672|446404|457865)').hasMatch(digits)) {
      return CardBrand.mada;
    }
    // Meeza (Egypt domestic) detector — simplified.
    if (RegExp('^(515676|535989|627213)').hasMatch(digits)) {
      return CardBrand.meeza;
    }
    return CardBrand.unknown;
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i + 1) % 4 == 0 && i != digits.length - 1) buffer.write(' ');
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 1 && digits.length > 2) buffer.write('/');
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
