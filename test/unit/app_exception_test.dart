import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniter/core/errors/app_exception.dart';

void main() {
  group('wrapException()', () {
    test('passes AppException through unchanged', () {
      const original = NetworkException();
      final result = wrapException(original);
      expect(result, same(original));
      expect(result, isA<NetworkException>());
    });

    test('converts TimeoutException to RequestTimeoutException', () {
      final result = wrapException(TimeoutException('timed out'));
      expect(result, isA<RequestTimeoutException>());
    });

    test(
      'converts string containing TimeoutException to RequestTimeoutException',
      () {
        final result = wrapException(Exception('TimeoutException after 15s'));
        expect(result, isA<RequestTimeoutException>());
      },
    );

    test('converts SocketException string to NetworkException', () {
      final result = wrapException(
        Exception('SocketException: Connection refused'),
      );
      expect(result, isA<NetworkException>());
    });

    test('converts NetworkException string to NetworkException', () {
      final result = wrapException(Exception('NetworkException: no internet'));
      expect(result, isA<NetworkException>());
    });

    test('wraps unknown exceptions as UnknownException', () {
      final result = wrapException(Exception('some unexpected error'));
      expect(result, isA<UnknownException>());
    });
  });

  group('AppException hierarchy', () {
    test('NetworkException has correct default message', () {
      const e = NetworkException();
      expect(e.message, contains('เครือข่าย'));
      expect(e.userMessage, equals(e.message));
    });

    test('ServerException stores statusCode', () {
      const e = ServerException(404, 'not found');
      expect(e.statusCode, equals(404));
      expect(e.message, equals('not found'));
    });

    test('toString includes runtimeType', () {
      const e = UnauthorizedException();
      expect(e.toString(), contains('UnauthorizedException'));
    });
  });
}
