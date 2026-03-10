import 'dart:async';

/// Typed exception hierarchy for the application.
///
/// Use these instead of raw [Exception] or [String] so that UI layers
/// and BLoCs can react to specific error types consistently.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  /// User-facing message safe to display in the UI.
  String get userMessage => message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Network is unreachable (no connectivity).
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'ไม่สามารถเชื่อมต่อเครือข่ายได้ กรุณาตรวจสอบอินเทอร์เน็ต',
  ]);
}

/// Request timed out before a response was received.
class RequestTimeoutException extends AppException {
  const RequestTimeoutException([
    super.message = 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง',
  ]);
}

/// Server returned 401 – token is invalid or expired.
class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่',
  ]);
}

/// Server returned a non-2xx status code.
class ServerException extends AppException {
  const ServerException(this.statusCode, [String message = 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์'])
      : super(message);

  final int statusCode;
}

/// Response body could not be parsed into the expected model.
class ParseException extends AppException {
  const ParseException([
    super.message = 'ไม่สามารถอ่านข้อมูลที่ได้รับได้',
  ]);
}

/// Catch-all for unexpected errors.
class UnknownException extends AppException {
  const UnknownException([
    super.message = 'เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่',
  ]);
}

/// Helper – converts any raw [Object] into a typed [AppException].
AppException wrapException(Object e) {
  if (e is AppException) return e;
  if (e is TimeoutException || e.toString().contains('TimeoutException')) {
    return const RequestTimeoutException();
  }
  if (e.toString().contains('SocketException') ||
      e.toString().contains('NetworkException')) {
    return const NetworkException();
  }
  return UnknownException(e.toString());
}
