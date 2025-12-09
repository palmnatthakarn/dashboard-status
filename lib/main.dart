import 'package:flutter/material.dart';
import 'layouts/main_layout.dart';

void main() {
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
