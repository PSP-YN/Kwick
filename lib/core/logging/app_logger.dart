import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Structured, privacy-preserving application diagnostics.
///
/// Production logs contain only stable event names. Raw exceptions and stack
/// traces are restricted to debug builds to avoid leaking user data, tokens,
/// addresses, or provider documents into device logs.
abstract final class AppLogger {
  static const String _name = 'kwick';

  static void info(String event) {
    developer.log(_sanitizeEvent(event), name: _name, level: 800);
  }

  static void warning(String event) {
    developer.log(_sanitizeEvent(event), name: _name, level: 900);
  }

  static void error(String event, {Object? error, StackTrace? stackTrace}) {
    final safeEvent = _sanitizeEvent(event);
    if (kDebugMode && error != null) {
      developer.log(
        '$safeEvent (${error.runtimeType})',
        name: _name,
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }
    developer.log(safeEvent, name: _name, level: 1000);
  }

  static String _sanitizeEvent(String event) {
    final normalized = event
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_.-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return normalized.length > 80 ? normalized.substring(0, 80) : normalized;
  }
}
