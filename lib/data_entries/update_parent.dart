import 'package:flutter/material.dart';

class UpdateParentScreen extends StatelessWidget {
  final String userId;
  final String token;

  const UpdateParentScreen({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Parent')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Updating Parent ID: $userId'),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(labelText: 'New Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement update parent functionality
                print('Token: $token');
              },
              child: const Text('Update Parent'),
            ),
          ],
        ),
      ),
    );
  }
}