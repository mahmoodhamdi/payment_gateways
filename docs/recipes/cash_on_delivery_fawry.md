# Recipe: Cash-at-outlet with Fawry

Fawry is the answer for the ~40% of Egyptian customers who don't carry payment cards.

## End-to-end

```dart
Future<void> checkoutWithFawry(BuildContext context, Order order) async {
  final intent = PaymentIntent(
    id: order.id,
    amountMinorUnits: order.totalEgpPiastres,
    currency: Currency.egp,
    customer: order.customer,
  );

  final result = await gateways.checkout(
    intent: intent,
    method: const PaymentMethod.cash(type: CashType.fawryOutlet),
    context: context,
  );

  switch (result) {
    case PaymentPendingAction(:final reference, :final transactionId):
      await OrderService.markAwaitingCash(
        order.id,
        fawryReference: reference!,
        fawryTransactionId: transactionId,
      );
      if (!context.mounted) return;
      await showFawryReferenceSheet(context, reference);
    case PaymentFailure(:final error):
      showSnack(context, error.userMessage);
    default:
      // PaymentSuccess unlikely on first call for Fawry; defensive only.
      break;
  }
}
```

## Show the reference

```dart
Future<void> showFawryReferenceSheet(
  BuildContext context,
  String reference,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final t = PaymentGatewaysTheme.of(ctx);
      return Padding(
        padding: EdgeInsets.all(t.horizontalPadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments, size: 64, color: t.primary),
            const SizedBox(height: 16),
            Text(
              'دفع عند فوري',
              style: t.bodyText.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SelectableText(
              reference,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 32,
                letterSpacing: 4,
                color: t.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'اذهب إلى أقرب منفذ فوري وسلّم هذا الرقم — أو ادفع عبر '
              'تطبيق البنك. ستتلقى تأكيد الطلب خلال دقائق من السداد.',
              textAlign: TextAlign.center,
              style: t.captionText,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Share.share(
                'رقم فوري الخاص بطلبك: $reference',
              ),
              icon: const Icon(Icons.share),
              label: const Text('مشاركة الرقم'),
            ),
          ],
        ),
      );
    },
  );
}
```

## Poll for confirmation

```dart
Future<void> watchFawryStatus(String transactionId) async {
  final gateway = gateways.router.registered
      .firstWhere((g) => g.id == 'fawry');
  while (true) {
    final status = await gateway.getStatus(transactionId: transactionId);
    switch (status) {
      case PaymentStatus.succeeded:
        OrderService.markPaid(transactionId);
        return;
      case PaymentStatus.canceled || PaymentStatus.failed:
        OrderService.markFailed(transactionId);
        return;
      default:
        await Future.delayed(const Duration(minutes: 10));
    }
  }
}
```

Or — preferred for battery — subscribe to a backend websocket that pushes the webhook payload the moment Fawry POSTs it.

## Localisation

The Fawry flow is shown almost exclusively to Arabic-speaking customers. Make sure your `MaterialApp.locale` is `Locale('ar', 'EG')` and that the Fawry sheet renders RTL. The `PaymentGatewaysTheme` honours `Directionality`.

## Edge cases

- **Reference expires** (~72 hours): your UI should re-issue a fresh reference if the user opens the app again before paying.
- **Partial payment**: Fawry never accepts partial payments — the full reference amount is always charged.
- **Refunds**: not programmatic — handled by support via the Fawry merchant portal.
- **Receipt**: send the receipt only after the webhook confirms payment, not when the reference is issued.
