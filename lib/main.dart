// lib/main.dart
import 'package:flutter/material.dart';
import 'package:safenest/accounts/login_screen.dart';
import 'package:safenest/accounts/signup_screen.dart';
import 'package:safenest/features/user_management/parent_screen.dart';
import 'package:safenest/features/user_management/teacher_screen.dart';
import 'package:safenest/features/user_management/admin_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeNest',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const SignUpScreen(),
        '/parent_dashboard': (context) => const ParentDashboard(userId: '',),
        '/teacher_dashboard': (context) => const TeacherDashboard(userId: '',),
        '/admin_dashboard': (context) => const AdminDashboard(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
      },
    );
  }
}