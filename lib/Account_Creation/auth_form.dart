import 'package:flutter/material.dart';

/// A reusable authentication form widget that provides a consistent look and feel
/// for login and signup screens. Includes:
/// - Title and subtitle
/// - Custom logo
/// - Form fields (passed as children)
/// - Primary action button
/// - Alternate action link
/// - Loading state
/// - Error display
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
          // Main content area
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo with fade-in animation
                if (logo != null) ...[
                  AnimatedOpacity(
                    opacity: isLoading ? 0.5 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: logo!,
                  ),
                  const SizedBox(height: 20),
                ],
                // Title with scaling animation
                AnimatedScale(
                  scale: isLoading ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
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
                // White form container
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: double.infinity,
                    margin: EdgeInsets.only(top: isLoading ? 28 : 32),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isLoading ? 0.05 : 0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Error message display with slide animation
                          if (errorMessage != null)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, -0.5),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                key: ValueKey<String?>(errorMessage),
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red.shade800, 
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Form fields passed as children
                          ...children,
                          const SizedBox(height: 24),
                          // Primary action button with loading state
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: isLoading ? 56 : 50,
                            child: ElevatedButton(
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
                          ),
                          // Alternate action link
                          if (alternateActionText != null &&
                              onAlternateAction != null) ...[
                            const SizedBox(height: 20),
                            AnimatedOpacity(
                              opacity: isLoading ? 0.6 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Row(
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
          // Loading overlay
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