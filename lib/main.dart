import 'package:flutter/material.dart';
import 'package:safenest/accounts/login_screen.dart';
import 'package:safenest/accounts/signup_screen.dart';
import 'package:safenest/data_entries/add_child.dart';
import 'package:safenest/data_entries/add_parent.dart';
import 'package:safenest/data_entries/add_teacher.dart';
import 'package:safenest/data_entries/update_parent.dart';
import 'package:safenest/data_entries/update_teacher.dart';
import 'package:safenest/user_management/admin_dashboard.dart';
import 'package:safenest/user_management/parent_dashboard.dart';
import 'package:safenest/user_management/teacher_dashboard.dart';

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
        primaryColor: const Color(0xFF5271FF),
        scaffoldBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5271FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const SignUpScreen());
          case '/admin_dashboard':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => AdminDashboard(
                email: args['email'] ?? '',
                fullname: args['fullname'] ?? '',
                token: args['token'] ?? '',
              ),
            );
          case '/parent_dashboard':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => ParentDashboard(
                userId: args['userId'] ?? '',
                roleId: args['roleId'] ?? '',
                email: args['email'] ?? '',
                fullname: args['fullname'] ?? '',
                token: args['token'] ?? '',
              ),
            );
          case '/teacher_dashboard':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => TeacherDashboard(
                roleId: args['roleId'] ?? '',
                email: args['email'] ?? '',
                fullname: args['fullname'] ?? '',
                token: args['token'] ?? '', userId: '',
              ),
            );
          case '/new_child':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => AddChildScreen(
                parentId: args['parentId'] ?? '',
                token: args['token'] ?? '',
              ),
            );
          case '/new_parent':
            final token = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => AddParentScreen(token: token),
            );
          case '/new_teacher':
            final token = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => AddTeacherScreen(token: token),
            );
          case '/update_parent':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => UpdateParentScreen(
                userId: args['userId'] ?? '',
                token: args['token'] ?? '',
              ),
            );
          case '/update_teacher':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => UpdateTeacherScreen(
                userId: args['userId'] ?? '',
                token: args['token'] ?? '',
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(
                  child: Text('Route ${settings.name} not found',
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
            );
        }
      },
    );
  }
}