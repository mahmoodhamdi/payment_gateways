import 'package:flutter/material.dart';
import 'package:payment_gateways/src/core/money.dart';
import 'package:payment_gateways/src/core/payment_method.dart';
import 'package:payment_gateways/src/core/payment_result.dart';
import 'package:payment_gateways/src/ui/order_summary.dart';
import 'package:payment_gateways/src/ui/payment_gateways_theme.dart';
import 'package:payment_gateways/src/ui/payment_method_selector.dart';
import 'package:payment_gateways/src/ui/wallet_buttons.dart';

/// Top-level checkout widget that ties together the order summary, the
/// method selector, and the gateway-driven submit button.
///
/// The integrator owns the actual call to `PaymentGateways.checkout` and is
/// passed back the chosen [PaymentMethod] via [onPay].
class CheckoutForm extends StatefulWidget {
  const CheckoutForm({
    required this.total,
    required this.availableMethods,
    required this.onPay,
    super.key,
    this.summaryHeader,
    this.payButtonLabel,
    this.walletShortcut = const [],
  });

  final Money total;
  final List<PaymentMethod> availableMethods;
  final Future<PaymentResult> Function(PaymentMethod) onPay;
  final Widget? summaryHeader;
  final String? payButtonLabel;
  final List<WalletType> walletShortcut;

  @override
  State<CheckoutForm> createState() => _CheckoutFormState();
}

class _CheckoutFormState extends State<CheckoutForm> {
  PaymentMethod? _selected;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final t = PaymentGatewaysTheme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(t.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.summaryHeader != null) widget.summaryHeader!,
          SizedBox(height: t.verticalGap),
          OrderSummary(items: const [], total: widget.total),
          SizedBox(height: t.verticalGap * 1.5),
          if (widget.walletShortcut.isNotEmpty) ...[
            WalletButtons(
              wallets: widget.walletShortcut,
              onTap: (w) => _runPayment(PaymentMethod.wallet(type: w)),
            ),
            SizedBox(height: t.verticalGap),
            Row(
              children: [
                Expanded(child: Divider(color: t.divider)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.horizontalPadding / 2,
                  ),
                  child: Text('or pay with', style: t.captionText),
                ),
                Expanded(child: Divider(color: t.divider)),
              ],
            ),
            SizedBox(height: t.verticalGap),
          ],
          PaymentMethodSelector(
            available: widget.availableMethods,
            value: _selected,
            onChanged: (m) => setState(() => _selected = m),
          ),
          SizedBox(height: t.verticalGap * 1.5),
          ElevatedButton(
            onPressed: _selected == null || _loading
                ? null
                : () => _runPayment(_selected!),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.primary,
              foregroundColor: t.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.cornerRadius),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.payButtonLabel ?? 'Pay'),
          ),
        ],
      ),
    );
  }

  Future<void> _runPayment(PaymentMethod method) async {
    setState(() => _loading = true);
    try {
      await widget.onPay(method);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
