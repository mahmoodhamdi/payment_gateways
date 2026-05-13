import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payment_gateways/src/core/money.dart';
import 'package:payment_gateways/src/core/order_metadata.dart';
import 'package:payment_gateways/src/ui/payment_gateways_theme.dart';

/// A read-only summary of an order: line items + total.
///
/// Suitable for cart screens, post-payment receipts, and order confirmation
/// emails (when rendered to image / PDF).
class OrderSummary extends StatelessWidget {
  const OrderSummary({
    required this.items,
    required this.total,
    super.key,
    this.taxMinorUnits = 0,
    this.shippingMinorUnits = 0,
    this.discountMinorUnits = 0,
    this.locale,
  });

  final List<OrderLineItem> items;
  final Money total;
  final int taxMinorUnits;
  final int shippingMinorUnits;
  final int discountMinorUnits;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    final t = PaymentGatewaysTheme.of(context);
    final fmt = NumberFormat.currency(
      locale: locale?.toString() ?? Localizations.localeOf(context).toString(),
      symbol: total.currency.code,
      decimalDigits: total.currency.minorUnitExponent,
    );
    String money(int minor) {
      final major = total.currency.toMajorUnits(minor);
      return fmt.format(major);
    }

    final subtotal = items.fold<int>(
      0,
      (sum, item) => sum + item.lineTotalMinorUnits,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: t.horizontalPadding,
        vertical: t.verticalGap,
      ),
      decoration: BoxDecoration(
        color: t.surfaceVariant,
        borderRadius: BorderRadius.circular(t.cornerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items) ...[
            _Row(
              left: item.quantity > 1
                  ? '${item.name} × ${item.quantity}'
                  : item.name,
              right: money(item.lineTotalMinorUnits),
              style: t.bodyText,
            ),
            SizedBox(height: t.verticalGap / 2),
          ],
          Divider(color: t.divider),
          _Row(
            left: 'Subtotal',
            right: money(subtotal),
            style: t.captionText,
          ),
          if (shippingMinorUnits > 0)
            _Row(
              left: 'Shipping',
              right: money(shippingMinorUnits),
              style: t.captionText,
            ),
          if (taxMinorUnits > 0)
            _Row(
              left: 'Tax',
              right: money(taxMinorUnits),
              style: t.captionText,
            ),
          if (discountMinorUnits > 0)
            _Row(
              left: 'Discount',
              right: '-${money(discountMinorUnits)}',
              style: t.captionText.copyWith(color: t.success),
            ),
          SizedBox(height: t.verticalGap / 2),
          Divider(color: t.divider),
          _Row(
            left: 'Total',
            right: money(total.amountMinorUnits),
            style: t.bodyText.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.left,
    required this.right,
    required this.style,
  });

  final String left;
  final String right;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(left, style: style)),
        Text(right, style: style),
      ],
    );
  }
}
