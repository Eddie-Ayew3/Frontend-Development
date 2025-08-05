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
      appBar: AppBar(
        title: const Text('Update Teacher Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Updating Teacher ID: $userId'),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                labelText: 'New Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5271FF),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // TODO: Implement update teacher functionality
                print('Token: $token');
              },
              child: const Text(
                'Update Teacher',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}