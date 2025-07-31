import 'package:flutter/material.dart';
import 'package:safenest/accounts/login_screen.dart';
import 'package:safenest/accounts/signup_screen.dart';
import 'package:safenest/data_input/new_sections/new_parent.dart';
import 'package:safenest/data_input/new_sections/new_teacher.dart';
import 'package:safenest/data_input/update_details/update_parent.dart';
import 'package:safenest/data_input/update_details/update_teacher.dart';
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
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity, // Ensure consistent UI
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const SignUpScreen(),
        '/admin_dashboard': (context) => const AdminDashboard(), // Placeholder
        '/parent_dashboard': (context) => const ParentDashboard(userId: '',), // Placeholder
        '/teacher_dashboard': (context) => const TeacherDashboard(userId: '',), // Placeholder
        '/new_parent': (context)=> const AddParentScreen(),
        '/new_teacher':(context)=> const AddTeacherScreen(),
        '/update_parent': (context)=> const UpdateParentScreen(userId: '',),
        '/update_teacher': (context)=> const UpdateTeacherScreen(userId: '',),

      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Center(
            child: Text('Route ${settings.name} not found'),
          ),
        ),
      ),
    );
  }
}


// Placeholder widgets for dashboard screens




