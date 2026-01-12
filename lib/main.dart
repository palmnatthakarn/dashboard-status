import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'blocs/auth/auth_bloc.dart';
import 'dashboard_screen.dart';
import 'pages/login_page.dart';
import 'services/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? initError;
  try {
    if (const bool.fromEnvironment('dart.library.js_util')) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDKin_0NxIRwAI9v3rBV6HSAYJ0BgaIvA0",
          authDomain: "account-seaandhill.firebaseapp.com",
          projectId: "account-seaandhill",
          storageBucket: "account-seaandhill.firebasestorage.app",
          messagingSenderId: "157985041664",
          appId: "1:157985041664:web:8b0be72ead7b1aa695d7e5",
          measurementId: "G-63Z87H44Y3",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    initError = e;
  }

  // Initialize persistence after Firebase app is initialized
  if (initError == null) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  await initializeDateFormatting('th', null);

  if (initError != null) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Firebase Initialization Failed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    initError.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Please ensure google-services.json (Android) or GoogleService-Info.plist (iOS) is added to your project.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthRepository(),
      child: BlocProvider(
        create: (context) =>
            AuthBloc(authRepository: context.read<AuthRepository>())
              ..add(AppStarted()),
        child: MaterialApp(
          title: 'Monitor',
          //theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('th', 'TH'), Locale('en', 'US')],
          locale: const Locale('th', 'TH'),
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthSuccess) {
                return const DashboardScreen();
              }
              return const LoginPage();
            },
          ),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
