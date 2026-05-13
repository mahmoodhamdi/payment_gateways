import 'package:flutter/material.dart';

/// Theme extension that lets integrators customize the colors, spacing, and
/// typography used by all `payment_gateways` widgets without forking the
/// package.
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData.light().copyWith(
///     extensions: [
///       PaymentGatewaysTheme.fromSeed(const Color(0xFF34A853)),
///     ],
///   ),
/// );
/// ```
@immutable
class PaymentGatewaysTheme extends ThemeExtension<PaymentGatewaysTheme> {
  const PaymentGatewaysTheme({
    required this.primary,
    required this.onPrimary,
    required this.success,
    required this.danger,
    required this.surface,
    required this.surfaceVariant,
    required this.divider,
    required this.bodyText,
    required this.captionText,
    this.cornerRadius = 12,
    this.horizontalPadding = 16,
    this.verticalGap = 12,
  });

  factory PaymentGatewaysTheme.fromSeed(Color seed, {Brightness? brightness}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness ?? Brightness.light,
    );
    return PaymentGatewaysTheme(
      primary: scheme.primary,
      onPrimary: scheme.onPrimary,
      success: const Color(0xFF34A853),
      danger: scheme.error,
      surface: scheme.surface,
      surfaceVariant: scheme.surfaceContainerHighest,
      divider: scheme.outlineVariant,
      bodyText: TextStyle(
        fontSize: 16,
        color: scheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      captionText: TextStyle(
        fontSize: 13,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  final Color primary;
  final Color onPrimary;
  final Color success;
  final Color danger;
  final Color surface;
  final Color surfaceVariant;
  final Color divider;
  final TextStyle bodyText;
  final TextStyle captionText;
  final double cornerRadius;
  final double horizontalPadding;
  final double verticalGap;

  /// Static fallback used when the consumer hasn't supplied a theme
  /// extension. Kept light for the most common case.
  static const PaymentGatewaysTheme fallback = PaymentGatewaysTheme(
    primary: Color(0xFF1A73E8),
    onPrimary: Color(0xFFFFFFFF),
    success: Color(0xFF34A853),
    danger: Color(0xFFD93025),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F3F4),
    divider: Color(0xFFE0E0E0),
    bodyText: TextStyle(fontSize: 16, color: Color(0xFF202124)),
    captionText: TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
  );

  /// Convenience accessor.
  static PaymentGatewaysTheme of(BuildContext context) {
    return Theme.of(context).extension<PaymentGatewaysTheme>() ?? fallback;
  }

  @override
  PaymentGatewaysTheme copyWith({
    Color? primary,
    Color? onPrimary,
    Color? success,
    Color? danger,
    Color? surface,
    Color? surfaceVariant,
    Color? divider,
    TextStyle? bodyText,
    TextStyle? captionText,
    double? cornerRadius,
    double? horizontalPadding,
    double? verticalGap,
  }) {
    return PaymentGatewaysTheme(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      divider: divider ?? this.divider,
      bodyText: bodyText ?? this.bodyText,
      captionText: captionText ?? this.captionText,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      verticalGap: verticalGap ?? this.verticalGap,
    );
  }

  @override
  PaymentGatewaysTheme lerp(
    covariant ThemeExtension<PaymentGatewaysTheme>? other,
    double t,
  ) {
    if (other is! PaymentGatewaysTheme) return this;
    return PaymentGatewaysTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      bodyText: TextStyle.lerp(bodyText, other.bodyText, t)!,
      captionText: TextStyle.lerp(captionText, other.captionText, t)!,
      cornerRadius: lerpDouble(cornerRadius, other.cornerRadius, t),
      horizontalPadding:
          lerpDouble(horizontalPadding, other.horizontalPadding, t),
      verticalGap: lerpDouble(verticalGap, other.verticalGap, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
