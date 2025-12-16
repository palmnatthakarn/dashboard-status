import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'layouts/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitor',
      //theme: AppTheme.lightTheme,
      home: const MainLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}
