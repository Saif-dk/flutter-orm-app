import 'package:flutter/material.dart';
import 'package:orm_risk_assessment/ui/home_page.dart';
import 'package:orm_risk_assessment/ui/launch_page.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ORM Risk Assessment',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A6741),
          background: const Color(0xFF1A1A1A),
          surface: const Color(0xFF2A2A2A),
          primary: const Color(0xFF4A6741),
          secondary: const Color(0xFFB8D4A8),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        fontFamily: 'Courier New',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
          titleLarge: TextStyle(
            color: Color(0xFFB8D4A8),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          titleMedium: TextStyle(
            color: Color(0xFFD4E8C8),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4A6741)),
            borderRadius: BorderRadius.zero,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4A6741)),
            borderRadius: BorderRadius.zero,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFB8D4A8)),
            borderRadius: BorderRadius.zero,
          ),
          labelStyle: TextStyle(color: Color(0xFFB8D4A8)),
          hintStyle: TextStyle(color: Color(0xFF888888)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A6741),
            foregroundColor: const Color(0xFFD4E8C8),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: Color(0xFF5A7751)),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFF2A2A2A),
            foregroundColor: const Color(0xFFD4E8C8),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: Color(0xFF4A6741)),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
      home: const LaunchPage(),
      routes: {
        '/launch': (context) => const LaunchPage(),
        '/home': (context) => const HomePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}