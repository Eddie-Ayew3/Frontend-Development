import 'package:flutter/material.dart';
import 'package:safenest/api/New_api.dart';

class ParentDashboard extends StatelessWidget {
  final String roleId;
  final String email;
  final String fullname;
  final String token;
  
  const ParentDashboard({
    super.key,
    required this.roleId,
    required this.email,
    required this.fullname,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Dashboard - $roleId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, $fullname', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            Text('Email: $email', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/new_child',
                arguments: {
                  'parentId': roleId,
                  'token': token,
                },
              ),
              child: const Text('Add Child'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    try {
      await ApiService.logout();
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }
}