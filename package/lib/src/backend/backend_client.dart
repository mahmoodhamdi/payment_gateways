import 'dart:async';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:payment_gateways/src/core/payment_config.dart';
import 'package:payment_gateways/src/core/payment_error.dart';
import 'package:payment_gateways/src/core/payment_intent.dart';
import 'package:payment_gateways/src/core/payment_status.dart';
import 'package:payment_gateways/src/ui/card_input.dart';
import 'package:payment_gateways/src/utils/logger.dart';

/// Result of a card-confirmation call to the backend.
@immutable
class ConfirmCardResponse {
  const ConfirmCardResponse({
    required this.status,
    this.transactionId,
    this.actionUrl,
    this.error,
  });

  final PaymentStatus status;
  final String? transactionId;
  final Uri? actionUrl;
  final PaymentError? error;
}

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

  /// Hand the raw card to the backend for tokenization + confirmation.
  ///
  /// Card details are sent over TLS to `/api/checkout/confirm`, where the
  /// backend tokenizes via the gateway's server SDK and confirms the
  /// PaymentIntent. The backend MUST NOT persist the raw card.
  Future<ConfirmCardResponse> confirmCard({
    required String gatewayId,
    required String gatewayIntentId,
    required RawCardDetails rawCard,
    required String successUrl,
    required String failureUrl,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/checkout/confirm',
        data: {
          'gateway_id': gatewayId,
          'gateway_intent_id': gatewayIntentId,
          'card': {
            'number': rawCard.numberDigitsOnly,
            'exp_month': rawCard.expiryMonth,
            'exp_year': rawCard.expiryYear,
            'cvv': rawCard.cvv,
            if (rawCard.cardholderName != null)
              'cardholder_name': rawCard.cardholderName,
          },
          'return_urls': {
            'success': successUrl,
            'failure': failureUrl,
          },
        },
      );
      final body = response.data ?? const {};
      final statusRaw = body['status'] as String? ?? 'pending';
      final status = PaymentStatus.values.firstWhere(
        (s) => s.name == statusRaw,
        orElse: () => PaymentStatus.pending,
      );
      Uri? actionUrl;
      if (body['action_url'] is String) {
        actionUrl = Uri.parse(body['action_url'] as String);
      }
      return ConfirmCardResponse(
        status: status,
        transactionId: body['transaction_id'] as String?,
        actionUrl: actionUrl,
        error: _maybeErrorFromBody(body),
      );
    } on DioException catch (e) {
      _logger.error('confirmCard failed', error: e);
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

  PaymentError? _maybeErrorFromBody(Map<String, dynamic> body) {
    final code = body['error_code'] as String?;
    if (code == null) return null;
    return switch (code) {
      'insufficient_funds' => const InsufficientFundsError(),
      'card_declined' =>
        CardDeclinedError(reason: body['error_reason'] as String?),
      'expired_card' => const ExpiredCardError(),
      'invalid_cvv' => const InvalidCvvError(),
      '3ds_failed' => const ThreeDSecureFailedError(),
      _ => null,
    };
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
