import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safenest/Account_Creation/login_screen.dart';
import 'package:safenest/Account_Creation/signup_screen.dart';
import 'package:safenest/Teacher/teacher_logs.dart';
import 'package:safenest/Parent/add_child.dart';
import 'package:safenest/Admin/add_parent.dart';
import 'package:safenest/Admin/add_teacher.dart';
import 'package:safenest/Teacher/studentList.dart';
import 'package:safenest/Parent/update_parent.dart';
import 'package:safenest/Teacher/update_teacher.dart';
import 'package:safenest/Admin/admin_dashboard.dart';
import 'package:safenest/Parent/parent_dashboard.dart';
import 'package:safenest/Teacher/teacher_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test secure storage
  try {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'storage_test', value: 'test');
    final value = await storage.read(key: 'storage_test');
    if (value != 'test') {
      throw Exception('Secure storage test failed');
    }
    await storage.delete(key: 'storage_test');
  } catch (e) {
    debugPrint('Secure storage initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Modifiable: Web dashboard URL for admin error message
  static const String adminWebUrl = 'https://admin.mydomain.com';

  // Modifiable: Minimum screen width (in pixels) for admin dashboard access
  static const double minAdminWidth = 600.0;

  // Modifiable: Allowed roles for mobile
  static const List<String> mobileAllowedRoles = ['parent', 'teacher'];

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
        // Helper to check role and platform restrictions
        Widget checkAccess({
          required Widget child,
          required String routeName,
          Map<String, dynamic>? args,
        }) {
          final role = (args?['role'] ?? '').toString().toLowerCase();

          // Block admin on mobile
          if (!kIsWeb && role == 'admin') {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 80, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Admins are restricted on mobile. Please use the web dashboard.',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Visit: $adminWebUrl',
                        style: const TextStyle(color: Colors.blue, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5271FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Return to Login', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Block non-admin on web for admin routes
          if (kIsWeb && role != 'admin' && routeName == '/admin_dashboard') {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 80, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'This web app is for admins only. Please use the mobile app for your role.',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5271FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Return to Login', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Block small screens for admin dashboard on web
          if (kIsWeb && routeName == '/admin_dashboard') {
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < minAdminWidth) {
                  return Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.desktop_mac, size: 80, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text(
                              'Please use a tablet or desktop to access the admin dashboard.',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Current screen width: ${constraints.maxWidth.toStringAsFixed(0)}px (minimum required: $minAdminWidth px)',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5271FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Return to Login', style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return child;
              },
            );
          }

          return child;
        }

        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const SignUpScreen());
          case '/admin_dashboard':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => checkAccess(
                child: AdminDashboard(
                  email: args['email'] ?? '',
                  fullname: args['fullname'] ?? '',
                  token: args['token'] ?? '',
                ),
                routeName: settings.name!,
                args: args,
              ),
            );
          case '/parent_dashboard':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => checkAccess(
                child: ParentDashboard(
                  userId: args['userId'] ?? '',
                  roleId: args['roleId'] ?? '',
                  email: args['email'] ?? '',
                  fullname: args['fullname'] ?? '',
                  token: args['token'] ?? '',
                ),
                routeName: settings.name!,
                args: args,
              ),
            );
          case '/teacher_dashboard':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => checkAccess(
                child: TeacherDashboard(
                  userId: args['userId'] ?? '',
                  roleId: args['roleId'] ?? '',
                  email: args['email'] ?? '',
                  fullname: args['fullname'] ?? '',
                  token: args['token'] ?? '',
                ),
                routeName: settings.name!,
                args: args,
              ),
            );
          case '/studentList':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => checkAccess(
                child: TeacherClassStudents(
                  userId: args['userId'] ?? '',
                  roleId: args['roleId'] ?? '',
                  token: args['token'] ?? '',
                ),
                routeName: settings.name!,
                args: args,
              ),
            );
          case '/teacher_logs':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => checkAccess(
                child: PickupLogsPage(
                  userId: args['userId'] ?? '',
                  roleId: args['roleId'] ?? '',
                  token: args['token'] ?? '',
                ),
                routeName: settings.name!,
                args: args,
              ),
            );
          case '/parent_logs':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => checkAccess(
                child: PickupLogsPage(
                  userId: args['userId'] ?? '',
                  roleId: args['roleId'] ?? '',
                  token: args['token'] ?? '',
                ),
                routeName: settings.name!,
                args: args,
              ),
            );
          case '/new_child':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => checkAccess(
                child: AddChildScreen(
                  parentId: args['parentId'] ?? '',
                  token: args['token'] ?? '',
                ),
                routeName: settings.name!,
                args: args,
              ),
            );
          case '/new_parent':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => checkAccess(
                child: AddParentScreen(
                  token: args['token'] ?? '',
                ),
                routeName: settings.name!,
                args: args,
              ),
            );
          case '/new_teacher':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => checkAccess(
                child: AddTeacherScreen(
                  token: args['token'] ?? '',
                ),
                routeName: settings.name!,
                args: args,
              ),
            );
          case '/update_parent':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => checkAccess(
                child: UpdateParentScreen(
                  roleId: args['roleId'] ?? '',
                  token: args['token'] ?? '',
                ),
                routeName: settings.name!,
                args: args,
              ),
            );
          case '/update_teacher':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => checkAccess(
                child: UpdateTeacherScreen(
                  roleId: args['roleId'] ?? '',
                  token: args['token'] ?? '',
                ),
                routeName: settings.name!,
                args: args,
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(
                  child: Text(
                    'Route ${settings.name} not found',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}