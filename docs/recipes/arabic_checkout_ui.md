# Recipe: Arabic / RTL checkout UI

`payment_gateways` widgets honor `Directionality.of(context)`; when the surrounding `MaterialApp` is RTL, the form fields, separators, dividers, and money formatters reflow correctly.

## App setup

```dart
MaterialApp(
  locale: const Locale('ar', 'EG'),
  supportedLocales: const [
    Locale('en', 'US'),
    Locale('ar', 'EG'),
    Locale('ar', 'SA'),
  ],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  theme: ThemeData.light().copyWith(
    extensions: const [
      PaymentGatewaysTheme.fallback,
    ],
    textTheme: GoogleFonts.tajawalTextTheme(),
  ),
  home: const CheckoutScreen(),
);
```

`GlobalMaterialLocalizations` provides the Arabic strings for the Material widgets (cancel, OK, etc.). `GoogleFonts.tajawalTextTheme()` is a clean Arabic-friendly font; Inter (which the template ships) also has Arabic glyphs.

## Money formatting

`OrderSummary` uses `intl`'s `NumberFormat.currency(locale: ...)`. With locale `ar_EG`, `Money(amountMinorUnits: 12300, currency: Currency.egp)` renders as **١٢٣٫٠٠ ج.م.** (Arabic-Indic digits, Egyptian pound symbol on the right).

## Right-to-left forms

The `CardInput` widget uses `TextDirection.ltr` for the card number field itself (card numbers are LTR everywhere), but the field labels and helper text follow the surrounding direction. No code change needed — just wrap in `Directionality(textDirection: TextDirection.rtl, child: …)` or rely on the MaterialApp locale.

## Mixed languages

Many MENA apps display Arabic UI but ship to bilingual users. Use `Localizations.localeOf(context).languageCode` to switch your own copy:

```dart
String get payLabel =>
    Localizations.localeOf(context).languageCode == 'ar' ? 'ادفع' : 'Pay';

ElevatedButton(onPressed: ..., child: Text(payLabel));
```

## Receipt and result dialog

`PaymentResultDialog` defaults to English. Override with localized text:

```dart
PaymentResultDialog.show(
  context,
  result: result,
  primaryActionLabel: localize('done'),
  secondaryActionLabel: localize('cancel'),
);
```

For full coverage, fork `PaymentResultDialog` and wire it through your own `AppLocalizations`. v0.5 will ship built-in Arabic translations.

## Don't forget

- **Phone number direction**: phone numbers are LTR even inside an RTL form. The `TextField` for phone should set `textDirection: TextDirection.ltr`.
- **Date of expiry**: `MM/YY` is universally LTR — leave the expiry field as LTR.
- **Card number spacing**: Latin digits group in fours (e.g. `4242 4242 4242 4242`); avoid forcing Arabic-Indic digits inside the card number field, they confuse most users for that one field.
- **Fawry reference**: render in a monospace font, large size; users will read it aloud to outlet cashiers.
