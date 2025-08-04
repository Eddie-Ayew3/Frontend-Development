import 'package:flutter/material.dart';

class AuthForm extends StatelessWidget {
  final List<Widget> children;
  final String title;
  final String subtitle;
  final String actionText;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onAction;
  final String? alternateActionText;
  final VoidCallback? onAlternateAction;

  const AuthForm({
    required this.children,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
    this.isLoading = false,
    this.errorMessage,
    this.alternateActionText,
    this.onAlternateAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5271FF),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    subtitle,
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 32),
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 32),
                          if (errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ...children,
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: isLoading ? null : onAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5271FF),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    actionText,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white),
                                  ),
                          ),
                          if (alternateActionText != null &&
                              onAlternateAction != null) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : onAlternateAction,
                                  child: Text(alternateActionText!,
                                      style: const TextStyle(
                                          color: Color(0xFF5271FF))),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const ModalBarrier(
                dismissible: false, color: Colors.black54),
          if (isLoading)
            const Center(
                child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}