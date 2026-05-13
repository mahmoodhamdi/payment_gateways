import 'package:flutter/material.dart';
import 'package:payment_gateways/src/core/payment_method.dart';
import 'package:payment_gateways/src/ui/payment_gateways_theme.dart';

/// Renders Apple Pay / Google Pay / Vodafone Cash / Orange Cash buttons.
///
/// Each wallet button calls [onTap] with the corresponding wallet type. The
/// host integration is responsible for handling the actual wallet flow
/// (e.g. Stripe's `presentApplePay`).
class WalletButtons extends StatelessWidget {
  const WalletButtons({
    required this.wallets,
    required this.onTap,
    super.key,
  });

  final List<WalletType> wallets;
  final ValueChanged<WalletType> onTap;

  @override
  Widget build(BuildContext context) {
    if (wallets.isEmpty) return const SizedBox.shrink();
    final t = PaymentGatewaysTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final w in wallets) ...[
          _WalletButton(
            wallet: w,
            theme: t,
            onTap: () => onTap(w),
          ),
          SizedBox(height: t.verticalGap / 2),
        ],
      ],
    );
  }
}

class _WalletButton extends StatelessWidget {
  const _WalletButton({
    required this.wallet,
    required this.theme,
    required this.onTap,
  });

  final WalletType wallet;
  final PaymentGatewaysTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _styling(wallet, theme);
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.cornerRadius),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  (Color, Color, String) _styling(WalletType w, PaymentGatewaysTheme t) {
    return switch (w) {
      WalletType.applePay => (Colors.black, Colors.white, 'Pay'),
      WalletType.googlePay => (Colors.white, Colors.black, 'Google Pay'),
      WalletType.vodafoneCash => (
          const Color(0xFFE60000),
          Colors.white,
          'Vodafone Cash'
        ),
      WalletType.orangeCash => (
          const Color(0xFFFF7900),
          Colors.white,
          'Orange Cash'
        ),
      WalletType.etisalatCash => (
          const Color(0xFF1B7A5C),
          Colors.white,
          'Etisalat Cash'
        ),
      WalletType.mada => (
          const Color(0xFF84B135),
          Colors.white,
          'mada'
        ),
      WalletType.link => (t.primary, t.onPrimary, 'Link'),
      WalletType.payPalWallet => (
          const Color(0xFF003087),
          Colors.white,
          'PayPal'
        ),
    };
  }
}
