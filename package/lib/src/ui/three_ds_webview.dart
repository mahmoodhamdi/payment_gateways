import 'package:flutter/material.dart';
import 'package:payment_gateways/src/ui/payment_gateways_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Displays a 3-D Secure challenge or other gateway redirect URL in a
/// modal WebView. Returns one of:
///
/// - `true`  — gateway redirected to the configured success URL.
/// - `false` — gateway redirected to the configured failure URL.
/// - `null`  — the user backed out without completing.
class ThreeDSWebView extends StatefulWidget {
  const ThreeDSWebView({
    required this.actionUrl,
    required this.successUrlPrefix,
    required this.failureUrlPrefix,
    super.key,
    this.title,
  });

  final Uri actionUrl;
  final String successUrlPrefix;
  final String failureUrlPrefix;
  final String? title;

  static Future<bool?> show(
    BuildContext context, {
    required Uri actionUrl,
    required String successUrlPrefix,
    required String failureUrlPrefix,
    String? title,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => ThreeDSWebView(
          actionUrl: actionUrl,
          successUrlPrefix: successUrlPrefix,
          failureUrlPrefix: failureUrlPrefix,
          title: title,
        ),
      ),
    );
  }

  @override
  State<ThreeDSWebView> createState() => _ThreeDSWebViewState();
}

class _ThreeDSWebViewState extends State<ThreeDSWebView> {
  late final WebViewController _controller;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            if (req.url.startsWith(widget.successUrlPrefix)) {
              _finish(true);
              return NavigationDecision.prevent;
            }
            if (req.url.startsWith(widget.failureUrlPrefix)) {
              _finish(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(widget.actionUrl);
  }

  void _finish(bool ok) {
    if (_resolved) return;
    _resolved = true;
    if (!mounted) return;
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final t = PaymentGatewaysTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? '3-D Secure Authentication'),
        backgroundColor: t.primary,
        foregroundColor: t.onPrimary,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
