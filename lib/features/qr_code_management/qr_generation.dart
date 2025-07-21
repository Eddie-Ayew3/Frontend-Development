import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:safenest/api_services/file.dart';

class ParentQRCodeScreen extends StatefulWidget {
  const ParentQRCodeScreen({super.key});

  @override
  State<ParentQRCodeScreen> createState() => _ParentQRCodeScreenState();
}

class _ParentQRCodeScreenState extends State<ParentQRCodeScreen> {
  final TextEditingController _childIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _qrCodeData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _childIdController.dispose();
    super.dispose();
  }

  Future<void> _generateQRCode() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _qrCodeData = null;
    });

    try {
      final response = await ApiService.safeApiCall(
        () => ApiService.generateQRCode(_childIdController.text.trim()),
      );

      if (!mounted) return;

      if (response['qrCode'] == null) {
        throw  ApiException('No QR code data received');
      }

      setState(() {
        _qrCodeData = response['qrCode'];
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _mapErrorToMessage(e);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate QR code: ${_mapErrorToMessage(e)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred')),
        );
      }
    }
  }

  String _mapErrorToMessage(ApiException e) {
    switch (e.message) {
      case 'Invalid child ID':
        return 'The provided child ID is invalid';
      case 'Network error':
        return 'Please check your internet connection';
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5271FF),
      appBar: AppBar(title: const Text('Generate QR Code')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset('assets/safenest_icon.png', height: 120),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: AbsorbPointer(
                  absorbing: _isLoading,
                  child: Opacity(
                    opacity: _isLoading ? 0.6 : 1.0,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: Text(
                              'Generate Pickup QR Code',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_qrCodeData != null)
                            QRDisplayWidget(base64Image: _qrCodeData!)
                          else
                            const Text(
                              'Enter a child ID to generate a QR code',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 20),
                          _buildLabel('CHILD ID'),
                          TextFormField(
                            controller: _childIdController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF0F0F0),
                              hintText: 'Enter child ID',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a child ID';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _generateQRCode(),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _generateQRCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5271FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Generate QR Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Back to Dashboard',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          letterSpacing: 1,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class QRDisplayWidget extends StatelessWidget {
  final String base64Image;
  final VoidCallback? onRetry;

  const QRDisplayWidget({super.key, required this.base64Image, this.onRetry});

  @override
  Widget build(BuildContext context) {
    Uint8List? decodedImage;
    String? errorMessage;

    try {
      decodedImage = base64Image.contains(',')
          ? base64Decode(base64Image.split(',').last)
          : base64Decode(base64Image);
    } catch (e) {
      errorMessage = 'Failed to load QR code: ${e.toString()}';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (errorMessage != null) ...[
          Text(
            errorMessage,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
        ] else if (decodedImage != null) ...[
          const Text(
            'Scan this QR at the gate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Image.memory(
            decodedImage,
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.width * 0.6,
          ),
        ],
      ],
    );
  }
}

