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
  final Widget? logo;

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
    this.logo,
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
                const SizedBox(height: 40),
                if (logo != null) ...[
                  logo!,
                  const SizedBox(height: 20),
                ],
                Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16, 
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 32),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade800, 
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ...children,
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: isLoading ? null : onAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5271FF),
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white, 
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    actionText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          if (alternateActionText != null &&
                              onAlternateAction != null) ...[
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${alternateActionText!.split('?')[0]}?',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton(
                                  onPressed: isLoading ? null : onAlternateAction,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
                                  child: Text(
                                    alternateActionText!.split('?')[1].trim(),
                                    style: const TextStyle(
                                      color: Color(0xFF5271FF),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
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
              dismissible: false, 
              color: Colors.black54,
            ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 4,
              ),
            ),
        ],
      ),
    );
  }
}