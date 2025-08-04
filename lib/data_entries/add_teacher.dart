import 'package:flutter/material.dart';

class AddTeacherScreen extends StatelessWidget {
  final String token;

  const AddTeacherScreen({
    super.key,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Teacher')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(labelText: 'Full Name'),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement add teacher functionality
                print('Token: $token');
              },
              child: const Text('Save Teacher'),
            ),
          ],
        ),
      ),
    );
  }
}