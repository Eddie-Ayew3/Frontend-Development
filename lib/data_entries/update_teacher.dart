import 'package:flutter/material.dart';

class UpdateTeacherScreen extends StatelessWidget {
  final String userId;
  final String token;

  const UpdateTeacherScreen({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Teacher')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Updating Teacher ID: $userId'),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(labelText: 'New Subject'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement update teacher functionality
                print('Token: $token');
              },
              child: const Text('Update Teacher'),
            ),
          ],
        ),
      ),
    );
  }
}