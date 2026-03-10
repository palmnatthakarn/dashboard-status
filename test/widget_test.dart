// widget_test.dart
// LoginPage depends on Firebase + FlutterSecureStorage platform channels
// which are unavailable in widget test environment without full native mocking.
// We test only that the BLoC + widget tree compiles and that BlocProvider setup is valid.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniter/blocs/auth/auth_bloc.dart';
import 'package:moniter/services/auth_repository.dart';

class FakeAuthRepository extends AuthRepository {
  @override
  Future<bool> checkSession() async => false;
  @override
  Future<String> login(String u, String p) async => 'token';
  @override
  Future<void> logout() async {}
  @override
  Future<String> loginWithGoogle() async => 'g_token';
}

void main() {
  group('AuthBloc + Widget integration', () {
    test('AuthBloc can be created with FakeAuthRepository', () {
      final repo = FakeAuthRepository();
      final bloc = AuthBloc(authRepository: repo);
      expect(bloc.state, isA<AuthInitial>());
      bloc.close();
    });

    test('AuthBloc emits AuthLoading then AuthInitial on AppStarted (no session)', () async {
      final repo = FakeAuthRepository();
      final bloc = AuthBloc(authRepository: repo);
      final states = <AuthState>[];
      final sub = bloc.stream.listen(states.add);
      bloc.add(AppStarted());
      await Future.delayed(const Duration(milliseconds: 200));
      await sub.cancel();
      expect(states.first, isA<AuthLoading>());
      expect(states.last, isA<AuthInitial>());
      await bloc.close();
    });

    testWidgets('MaterialApp with BlocProvider renders without crash',
        (tester) async {
      final repo = FakeAuthRepository();
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => AuthBloc(authRepository: repo),
          child: const MaterialApp(
            home: Scaffold(body: Text('Auth Bloc OK')),
          ),
        ),
      );
      expect(find.text('Auth Bloc OK'), findsOneWidget);
    });
  });
}
