import 'package:flutter/material.dart';
import 'package:video_tape_store/Pages/Auth/LoginPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie Store App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        primaryColor: const Color(0xFF3498DB),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3498DB),
          secondary: Color(0xFF2ECC71),
          surface: Color(0xFF2D2D2D),
        ),
      ),
      home: const LoginPage(),
    );
  }
}