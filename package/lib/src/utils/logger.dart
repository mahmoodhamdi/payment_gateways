import 'package:flutter/foundation.dart';
import 'package:payment_gateways/src/utils/sensitive_fields.dart';

/// Severity of a log record.
enum LogLevel { debug, info, warn, error }

/// Logger surface used by the SDK. Pluggable so integrators can wire to
/// their existing logging stack. The default sink redacts sensitive fields
/// and only logs in debug mode.
class PaymentLogger {
  PaymentLogger({this.minimumLevel = LogLevel.info, LogSink? sink})
      : _sink = sink ?? const _DebugPrintSink();

  final LogLevel minimumLevel;
  final LogSink _sink;

  void debug(String message, {Map<String, Object?>? data}) =>
      _emit(LogLevel.debug, message, data);

  void info(String message, {Map<String, Object?>? data}) =>
      _emit(LogLevel.info, message, data);

  void warn(String message, {Map<String, Object?>? data}) =>
      _emit(LogLevel.warn, message, data);

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    final enriched = <String, Object?>{
      if (data != null) ...data,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stack_trace': stackTrace.toString(),
    };
    _emit(LogLevel.error, message, enriched);
  }

  void _emit(LogLevel level, String message, Map<String, Object?>? data) {
    if (level.index < minimumLevel.index) return;
    final redacted = data == null ? null : redact(data);
    _sink.write(level, message, redacted);
  }
}

abstract interface class LogSink {
  void write(LogLevel level, String message, Map<String, Object?>? data);
}

class _DebugPrintSink implements LogSink {
  const _DebugPrintSink();

  @override
  void write(LogLevel level, String message, Map<String, Object?>? data) {
    if (!kDebugMode) return;
    final prefix = '[payment_gateways][${level.name.toUpperCase()}]';
    if (data == null || data.isEmpty) {
      debugPrint('$prefix $message');
    } else {
      debugPrint('$prefix $message  $data');
    }
  }
}
