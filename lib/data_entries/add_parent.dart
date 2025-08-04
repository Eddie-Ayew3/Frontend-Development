import 'package:flutter/material.dart';

class AddParentScreen extends StatelessWidget {
  final String token;

  const AddParentScreen({
    super.key,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Parent')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(labelText: 'Full Name'),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement add parent functionality
                print('Token: $token');
              },
              child: const Text('Save Parent'),
            ),
          ],
        ),
      ),
    );
  }
}