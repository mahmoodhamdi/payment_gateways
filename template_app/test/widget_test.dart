import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payment_gateways_template/app.dart';

void main() {
  testWidgets('CheckoutApp renders without throwing', (tester) async {
    await tester.pumpWidget(const CheckoutApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
