import 'package:flutter/material.dart';
import 'package:payment_gateways_template/core/widgets/cutom_app_bar.dart';
import 'package:payment_gateways_template/features/checkout/presentation/widgets/payment_details_view_body.dart';

class PaymentDetailsView extends StatelessWidget {
  const PaymentDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(title: 'Payment Details'),
      body: const PaymentDetailsViewBody(),
    );
  }
}
