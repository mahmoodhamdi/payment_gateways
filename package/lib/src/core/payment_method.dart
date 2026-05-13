import 'package:meta/meta.dart';

/// Top-level family of payment methods a customer can use.
///
/// Use Dart 3 pattern matching to switch:
///
/// ```dart
/// switch (method) {
///   case CardPaymentMethod():       /* show card form */
///   case WalletPaymentMethod(:final type): /* Apple Pay, etc. */
///   case CashPaymentMethod():       /* Fawry outlet reference */
///   case BankTransferMethod():      /* bank transfer instructions */
/// }
/// ```
@immutable
sealed class PaymentMethod {
  const PaymentMethod();

  Map<String, dynamic> toJson();

  /// Identifier used in routing rules and persistence.
  String get kind;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return switch (json['kind'] as String) {
      'card' => CardPaymentMethod.fromJson(json),
      'wallet' => WalletPaymentMethod.fromJson(json),
      'cash' => CashPaymentMethod.fromJson(json),
      'bank_transfer' => BankTransferMethod.fromJson(json),
      final k => throw FormatException('Unknown PaymentMethod kind', k),
    };
  }

  /// Convenience constructor for common case: any card.
  const factory PaymentMethod.card({CardBrand? brandHint}) = CardPaymentMethod;

  /// Convenience constructor for digital wallets.
  const factory PaymentMethod.wallet({required WalletType type}) =
      WalletPaymentMethod;

  /// Convenience constructor for cash-at-outlet payments.
  const factory PaymentMethod.cash({required CashType type}) =
      CashPaymentMethod;

  /// Convenience constructor for direct bank transfers.
  const factory PaymentMethod.bankTransfer({String? bank}) = BankTransferMethod;
}

/// Card payment (Visa, Mastercard, Amex, mada, etc.).
final class CardPaymentMethod extends PaymentMethod {
  const CardPaymentMethod({this.brandHint});

  final CardBrand? brandHint;

  @override
  String get kind => 'card';

  @override
  Map<String, dynamic> toJson() => {
        'kind': kind,
        if (brandHint != null) 'brand_hint': brandHint!.name,
      };

  factory CardPaymentMethod.fromJson(Map<String, dynamic> json) {
    final brandHintRaw = json['brand_hint'] as String?;
    return CardPaymentMethod(
      brandHint: brandHintRaw != null
          ? CardBrand.values.firstWhere(
              (b) => b.name == brandHintRaw,
              orElse: () => CardBrand.unknown,
            )
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CardPaymentMethod && other.brandHint == brandHint;

  @override
  int get hashCode => Object.hash('card', brandHint);

  @override
  String toString() => 'CardPaymentMethod(brandHint: $brandHint)';
}

/// Digital wallet payment (Apple Pay, Google Pay, Vodafone Cash, etc.).
final class WalletPaymentMethod extends PaymentMethod {
  const WalletPaymentMethod({required this.type});

  final WalletType type;

  @override
  String get kind => 'wallet';

  @override
  Map<String, dynamic> toJson() => {
        'kind': kind,
        'wallet_type': type.name,
      };

  factory WalletPaymentMethod.fromJson(Map<String, dynamic> json) {
    final typeName = json['wallet_type'] as String;
    return WalletPaymentMethod(
      type: WalletType.values.firstWhere(
        (w) => w.name == typeName,
        orElse: () =>
            throw FormatException('Unknown wallet type', typeName),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WalletPaymentMethod && other.type == type;

  @override
  int get hashCode => Object.hash('wallet', type);

  @override
  String toString() => 'WalletPaymentMethod(type: $type)';
}

/// Cash payment via a physical outlet or ATM (Fawry, Aman, etc.).
final class CashPaymentMethod extends PaymentMethod {
  const CashPaymentMethod({required this.type});

  final CashType type;

  @override
  String get kind => 'cash';

  @override
  Map<String, dynamic> toJson() => {
        'kind': kind,
        'cash_type': type.name,
      };

  factory CashPaymentMethod.fromJson(Map<String, dynamic> json) {
    final typeName = json['cash_type'] as String;
    return CashPaymentMethod(
      type: CashType.values.firstWhere(
        (c) => c.name == typeName,
        orElse: () => throw FormatException('Unknown cash type', typeName),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CashPaymentMethod && other.type == type;

  @override
  int get hashCode => Object.hash('cash', type);

  @override
  String toString() => 'CashPaymentMethod(type: $type)';
}

/// Direct bank transfer (slow — settlement may take 1–3 business days).
final class BankTransferMethod extends PaymentMethod {
  const BankTransferMethod({this.bank});

  final String? bank;

  @override
  String get kind => 'bank_transfer';

  @override
  Map<String, dynamic> toJson() => {
        'kind': kind,
        if (bank != null) 'bank': bank,
      };

  factory BankTransferMethod.fromJson(Map<String, dynamic> json) {
    return BankTransferMethod(bank: json['bank'] as String?);
  }

  @override
  bool operator ==(Object other) =>
      other is BankTransferMethod && other.bank == bank;

  @override
  int get hashCode => Object.hash('bank_transfer', bank);

  @override
  String toString() => 'BankTransferMethod(bank: $bank)';
}

/// Card brand hint. The gateway is the authoritative source — this enum only
/// helps with UI choices (showing a logo, validating BIN ranges, etc.).
enum CardBrand {
  visa,
  mastercard,
  amex,
  discover,
  mada,
  meeza,
  unknown,
}

/// Wallet provider for a [WalletPaymentMethod].
enum WalletType {
  applePay,
  googlePay,
  vodafoneCash,
  orangeCash,
  etisalatCash,
  mada,
  link, // Stripe Link
  payPalWallet,
}

/// Cash payment channel for [CashPaymentMethod].
enum CashType {
  fawryOutlet,
  fawryAtm,
  amanOutlet,
}
