import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const DashCashApp());
}

class DashCashApp extends StatelessWidget {
  const DashCashApp({super.key}); // <--- Updated to super parameter

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DashCash',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Responsive Light & Dark Mode support
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
