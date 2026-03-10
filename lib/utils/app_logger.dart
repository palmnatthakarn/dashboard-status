import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kDebugMode;

/// App-wide logging utility.
///
/// Wraps [dart:developer log] behind a [kDebugMode] guard so that
/// verbose log output is **completely stripped from release builds**.
///
/// Usage:
/// ```dart
/// import '../utils/app_logger.dart';
///
/// dLog('Fetching data...');
/// dLog('Error: $e', name: 'AuthRepository', error: e);
/// ```
void dLog(
  String message, {
  String name = 'Monitor',
  Object? error,
  StackTrace? stackTrace,
}) {
  if (kDebugMode) {
    developer.log(message, name: name, error: error, stackTrace: stackTrace);
  }
}
