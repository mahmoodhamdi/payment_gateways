import 'package:flutter/material.dart';
import 'package:payment_getaways/features/checkout/presentation/views/my_cart_view.dart';

class CheckoutApp extends StatelessWidget {
  const CheckoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Payment Getaways',
      home: MyCartView(),
    );
  }
}
