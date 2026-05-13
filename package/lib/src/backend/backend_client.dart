import 'dart:async';

import 'package:dio/dio.dart';
import 'package:payment_gateways/src/core/payment_config.dart';
import 'package:payment_gateways/src/core/payment_error.dart';
import 'package:payment_gateways/src/core/payment_intent.dart';
import 'package:payment_gateways/src/core/payment_status.dart';
import 'package:payment_gateways/src/utils/logger.dart';

/// Thin HTTP client that talks to the backend companion for the operations
/// that *must* happen server-side (intent creation, refunds, status polls).
///
/// Adapters never speak directly to gateways with secret keys; they hit
/// this client which speaks to your backend, which holds the secrets.
class BackendClient {
  BackendClient({
    required this.config,
    PaymentLogger? logger,
    Dio? dio,
  })  : _logger = logger ?? PaymentLogger(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: config.backendBaseUrl.toString(),
                connectTimeout: config.networkTimeout,
                receiveTimeout: config.networkTimeout,
                sendTimeout: config.networkTimeout,
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  final PaymentConfig config;
  final PaymentLogger _logger;
  final Dio _dio;

  /// Create a payment intent on the backend.
  ///
  /// Backend is responsible for:
  /// 1. Authenticating with the chosen gateway using its secret key.
  /// 2. Returning [PaymentIntent] enriched with `gatewayIntentId` and
  ///    `clientSecret` for the client to confirm against the gateway.
  Future<PaymentIntent> createIntent({
    required PaymentIntent intent,
    required String gatewayId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/checkout',
        data: {
          'gateway_id': gatewayId,
          'intent': intent.toJson(),
        },
      );
      final body = response.data ?? const {};
      if (body['intent'] is! Map<String, dynamic>) {
        throw const ConfigError(details: 'Backend response missing "intent".');
      }
      final updated = PaymentIntent.fromJson(
        Map<String, dynamic>.from(body['intent'] as Map<String, dynamic>),
      );
      return updated.copyWith(
        gatewayIntentId: body['gateway_intent_id'] as String?,
        clientSecret: body['client_secret'] as String?,
        gatewayName: gatewayId,
      );
    } on DioException catch (e) {
      _logger.error(
        'createIntent failed',
        error: e,
        data: {'gateway_id': gatewayId, 'intent_id': intent.id},
      );
      throw _toPaymentError(e, gatewayId);
    }
  }

  Future<PaymentStatus> getStatus({
    required String transactionId,
    required String gatewayId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/transactions/$transactionId',
        queryParameters: {'gateway_id': gatewayId},
      );
      final body = response.data ?? const {};
      final raw = body['status'] as String? ?? 'pending';
      return PaymentStatus.values.firstWhere(
        (s) => s.name == raw,
        orElse: () => PaymentStatus.pending,
      );
    } on DioException catch (e) {
      _logger.error('getStatus failed', error: e);
      throw _toPaymentError(e, gatewayId);
    }
  }

  Future<bool> refund({
    required String transactionId,
    required String gatewayId,
    int? amountMinorUnits,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/refunds',
        data: {
          'gateway_id': gatewayId,
          'transaction_id': transactionId,
          if (amountMinorUnits != null)
            'amount_minor_units': amountMinorUnits,
        },
      );
      final body = response.data ?? const {};
      return body['refunded'] == true;
    } on DioException catch (e) {
      _logger.error('refund failed', error: e);
      throw _toPaymentError(e, gatewayId);
    }
  }

  PaymentError _toPaymentError(DioException e, String gatewayId) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkError();
    }
    final raw = e.response?.data;
    if (raw is Map<String, dynamic>) {
      final code = raw['code'] as String?;
      switch (code) {
        case 'insufficient_funds':
          return const InsufficientFundsError();
        case 'card_declined':
          return CardDeclinedError(reason: raw['reason'] as String?);
        case 'expired_card':
          return const ExpiredCardError();
        case 'invalid_cvv':
          return const InvalidCvvError();
        case '3ds_failed':
          return const ThreeDSecureFailedError();
      }
    }
    return GatewayUnavailableError(
      gateway: gatewayId,
      gatewayMessage: e.message,
    );
  }
}
