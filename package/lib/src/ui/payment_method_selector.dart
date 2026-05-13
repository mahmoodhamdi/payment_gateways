import 'package:flutter/material.dart';
import 'package:payment_gateways/src/core/payment_method.dart';
import 'package:payment_gateways/src/ui/payment_gateways_theme.dart';

/// A radio-list selector for [PaymentMethod] choices.
///
/// The integrator supplies the list of [available] methods (driven by which
/// gateways are configured and `canAccept`). The widget exposes the chosen
/// method via [onChanged].
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    required this.available,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<PaymentMethod> available;
  final PaymentMethod? value;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = PaymentGatewaysTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final method in available)
          _MethodTile(
            method: method,
            selected: method == value,
            theme: t,
            onTap: () => onChanged(method),
          ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final PaymentGatewaysTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(theme.cornerRadius),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: theme.verticalGap / 2),
        padding: EdgeInsets.symmetric(
          horizontal: theme.horizontalPadding,
          vertical: theme.verticalGap,
        ),
        decoration: BoxDecoration(
          color: selected
              ? theme.primary.withValues(alpha: 0.08)
              : theme.surface,
          border: Border.all(
            color: selected ? theme.primary : theme.divider,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(theme.cornerRadius),
        ),
        child: Row(
          children: [
            Icon(_iconFor(method), color: theme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _labelFor(method),
                style: theme.bodyText,
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: theme.primary),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(PaymentMethod method) => switch (method) {
        CardPaymentMethod() => Icons.credit_card,
        WalletPaymentMethod() => Icons.account_balance_wallet,
        CashPaymentMethod() => Icons.payments,
        BankTransferMethod() => Icons.account_balance,
      };

  String _labelFor(PaymentMethod method) => switch (method) {
        CardPaymentMethod() => 'Card',
        WalletPaymentMethod(:final type) => _walletLabel(type),
        CashPaymentMethod(:final type) => _cashLabel(type),
        BankTransferMethod(:final bank) =>
          'Bank transfer${bank != null ? ' ($bank)' : ''}',
      };

  String _walletLabel(WalletType t) => switch (t) {
        WalletType.applePay => 'Apple Pay',
        WalletType.googlePay => 'Google Pay',
        WalletType.vodafoneCash => 'Vodafone Cash',
        WalletType.orangeCash => 'Orange Cash',
        WalletType.etisalatCash => 'Etisalat Cash',
        WalletType.mada => 'mada',
        WalletType.link => 'Link',
        WalletType.payPalWallet => 'PayPal',
      };

  String _cashLabel(CashType t) => switch (t) {
        CashType.fawryOutlet => 'Fawry (cash at outlet)',
        CashType.fawryAtm => 'Fawry (ATM)',
        CashType.amanOutlet => 'Aman (cash at outlet)',
      };
}
