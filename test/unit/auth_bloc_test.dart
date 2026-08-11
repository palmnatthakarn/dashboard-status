// auth_bloc_test.dart
// Uses only flutter_test (built-in) — no bloc_test/mocktail needed.
// We create a manual fake AuthRepository instead of using Mock.

import 'package:flutter_test/flutter_test.dart';
import 'package:moniter/blocs/auth/auth_bloc.dart';
import 'package:moniter/services/auth_repository.dart';

// ─── Manual fake of AuthRepository ───────────────────────────────────────────

class FakeAuthRepository extends AuthRepository {
  final bool sessionExists;
  final String? loginToken;
  final bool loginShouldThrow;

  FakeAuthRepository({
    this.sessionExists = false,
    this.loginToken,
    this.loginShouldThrow = false,
  });

  @override
  Future<bool> checkSession() async => sessionExists;

  @override
  Future<String> login(String username, String password) async {
    if (loginShouldThrow) throw Exception('Invalid credentials');
    return loginToken ?? 'fake_token';
  }

  @override
  Future<void> logout() async {}

  @override
  Future<String> loginWithGoogle() async => 'google_token';
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

// Collect bloc states until predicate matches (max 5 states for safety)
Future<List<AuthState>> collectStates(
  AuthBloc bloc,
  void Function() addEvent, {
  int count = 2,
}) async {
  final states = <AuthState>[];
  final subscription = bloc.stream.listen(states.add);
  addEvent();
  // Wait long enough for async emission
  await Future.delayed(const Duration(milliseconds: 300));
  await subscription.cancel();
  return states;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('AuthRepository session-expired detection', () {
    test('recognizes token expiry and unauthorized variants', () {
      const messages = [
        'Exception: Token หมดอายุ กรุณาเข้าสู่ระบบใหม่',
        'Exception: ไม่พบ Token กรุณาเข้าสู่ระบบใหม่',
        'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่',
        'Token expired',
        'Session expired',
        'Unauthorized',
        'Failed to load - Status: 401',
        'status=401',
      ];

      for (final message in messages) {
        expect(
          AuthRepository.isSessionExpiredError(message),
          isTrue,
          reason: message,
        );
      }
    });
  });

  group('AuthBloc — AppStarted', () {
    test('emits [AuthLoading, AuthSuccess] when session exists', () async {
      final bloc = AuthBloc(
        authRepository: FakeAuthRepository(sessionExists: true),
      );
      final states = await collectStates(bloc, () => bloc.add(AppStarted()));
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthSuccess>());
      await bloc.close();
    });

    test('emits [AuthLoading, AuthInitial] when no session', () async {
      final bloc = AuthBloc(
        authRepository: FakeAuthRepository(sessionExists: false),
      );
      final states = await collectStates(bloc, () => bloc.add(AppStarted()));
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthInitial>());
      await bloc.close();
    });
  });

  group('AuthBloc — LoginRequested', () {
    test('emits [AuthLoading, AuthSuccess] on successful login', () async {
      final bloc = AuthBloc(
        authRepository: FakeAuthRepository(loginToken: 'tok123'),
      );
      final states = await collectStates(
        bloc,
        () => bloc.add(LoginRequested(username: 'user', password: 'pass')),
      );
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthSuccess>());
      expect((states[1] as AuthSuccess).token, equals('tok123'));
      await bloc.close();
    });

    test('emits [AuthLoading, AuthFailure] on login failure', () async {
      final bloc = AuthBloc(
        authRepository: FakeAuthRepository(loginShouldThrow: true),
      );
      final states = await collectStates(
        bloc,
        () => bloc.add(LoginRequested(username: 'bad', password: 'wrong')),
      );
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthFailure>());
      final failure = states[1] as AuthFailure;
      expect(failure.error, contains('Invalid credentials'));
      await bloc.close();
    });
  });

  group('AuthBloc — LogoutRequested', () {
    test('emits [AuthLoading, AuthInitial] on logout', () async {
      final bloc = AuthBloc(authRepository: FakeAuthRepository());
      final states = await collectStates(
        bloc,
        () => bloc.add(LogoutRequested()),
      );
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthInitial>());
      await bloc.close();
    });
  });
}
