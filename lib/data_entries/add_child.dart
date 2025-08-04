import 'package:flutter/material.dart';

class AddChildScreen extends StatelessWidget {
  final String parentId;
  final String token;

  const AddChildScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Child')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Parent ID: $parentId'),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(labelText: 'Child Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement add child functionality
                print('Token: $token');
              },
              child: const Text('Save Child'),
            ),
          ],
        ),
      ),
    );
  }
}