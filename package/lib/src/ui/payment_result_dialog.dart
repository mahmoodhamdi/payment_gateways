import 'package:flutter/material.dart';
import 'package:payment_gateways/src/core/payment_result.dart';
import 'package:payment_gateways/src/ui/payment_gateways_theme.dart';

/// Modal dialog that presents the outcome of a payment attempt.
class PaymentResultDialog extends StatelessWidget {
  const PaymentResultDialog({
    required this.result,
    super.key,
    this.onPrimaryAction,
    this.primaryActionLabel,
    this.onSecondaryAction,
    this.secondaryActionLabel,
  });

  final PaymentResult result;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;

  static Future<void> show(
    BuildContext context, {
    required PaymentResult result,
    VoidCallback? onPrimaryAction,
    String? primaryActionLabel,
    VoidCallback? onSecondaryAction,
    String? secondaryActionLabel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentResultDialog(
        result: result,
        onPrimaryAction: onPrimaryAction,
        primaryActionLabel: primaryActionLabel,
        onSecondaryAction: onSecondaryAction,
        secondaryActionLabel: secondaryActionLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = PaymentGatewaysTheme.of(context);
    final (icon, color, title, body) = _decode(result, t);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.cornerRadius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: t.horizontalPadding * 1.5,
          vertical: t.verticalGap * 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 64),
            SizedBox(height: t.verticalGap),
            Text(
              title,
              style: t.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: t.verticalGap / 2),
            Text(body, style: t.captionText, textAlign: TextAlign.center),
            SizedBox(height: t.verticalGap * 1.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onSecondaryAction != null) ...[
                  TextButton(
                    onPressed: onSecondaryAction,
                    child: Text(secondaryActionLabel ?? 'Cancel'),
                  ),
                  SizedBox(width: t.horizontalPadding),
                ],
                ElevatedButton(
                  onPressed: onPrimaryAction ??
                      () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.primary,
                    foregroundColor: t.onPrimary,
                  ),
                  child: Text(primaryActionLabel ?? 'OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, String, String) _decode(
    PaymentResult result,
    PaymentGatewaysTheme t,
  ) {
    return switch (result) {
      PaymentSuccess(:final transactionId) => (
          Icons.check_circle_outline,
          t.success,
          'Payment successful',
          'Transaction ID: $transactionId',
        ),
      PaymentFailure(:final error) => (
          Icons.error_outline,
          t.danger,
          'Payment failed',
          error.userMessage,
        ),
      PaymentCanceled() => (
          Icons.cancel_outlined,
          t.captionText.color ?? Colors.grey,
          'Payment canceled',
          'You canceled the payment.',
        ),
      PaymentPendingAction(:final reference) => (
          Icons.hourglass_top,
          t.primary,
          'Action required',
          reference != null
              ? 'Reference: $reference'
              : 'Please complete the next step to finish your payment.',
        ),
    };
  }
}
