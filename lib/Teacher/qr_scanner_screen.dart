import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:safenest/Api_Service/New_api.dart';

class QRScannerScreen extends StatefulWidget {
  final String token;

  const QRScannerScreen({super.key, required this.token});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController cameraController;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;

  static const _primaryColor = Color(0xFF5271FF);
  static const _whiteColor = Colors.white;
  static const _lightGrey = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

Future<void> _verifyQRCode(String qrCode) async {
  if (_isProcessing || !mounted) return;

  debugPrint('Verifying QR: ${qrCode.substring(0, qrCode.length > 20 ? 20 : qrCode.length)}...');
  setState(() => _isProcessing = true);

  try {
    // Get the API service instance
    final apiService = ApiService();
    
    // Call verifyQRCode without explicitly passing token (handled by interceptor)
    final result = await apiService.verifyQRCode(qrCode: qrCode);
    
    if (!mounted) return;
    
    _showVerificationResult(
      success: true,
      childName: result['childName'] ?? 'Unknown Child',
      grade: result['grade'] ?? 'N/A',
      parentName: result['parentName'] ?? 'Unknown Parent',
      verifiedAt: result['verifiedAt'] ?? DateTime.now().toIso8601String(),
    );
  } on ApiException catch (e) {
    if (e.statusCode == 401 && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
    if (!mounted) return;
    _showVerificationResult(
      success: false,
      errorMessage: _getUserFriendlyErrorMessage(e.message),
    );
  } catch (e) {
    if (!mounted) return;
    _showVerificationResult(
      success: false,
      errorMessage: 'An unexpected error occurred',
    );
  } finally {
    if (mounted) setState(() => _isProcessing = false);
  }
}

  String _getUserFriendlyErrorMessage(String? technicalMessage) {
    if (technicalMessage == null) return 'Verification failed';
    
    if (technicalMessage.contains('expired')) {
      return 'This QR code has expired';
    } else if (technicalMessage.contains('invalid')) {
      return 'Invalid QR code format';
    } else if (technicalMessage.contains('already used')) {
      return 'This code has already been used';
    } else if (technicalMessage.contains('network')) {
      return 'Network error. Please check your connection';
    }
    
    return 'Verification failed. Please try again';
  }

void _showVerificationResult({
  required bool success,
  String? childName,
  String? grade,
  String? parentName,
  String? verifiedAt,
  String? errorMessage,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: success ? _primaryColor : Colors.red,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Center(
          child: Text(
            success ? 'PICKUP VERIFIED' : 'VERIFICATION FAILED',
            style: const TextStyle(
              color: _whiteColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
      content: success
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildVerificationDetail('Child', childName!),
                const Divider(height: 24),
                _buildVerificationDetail('Grade', grade!),
                const Divider(height: 24),
                _buildVerificationDetail('Parent', parentName!),
                const Divider(height: 24),
                _buildVerificationDetail('Time', _formatDateTime(verifiedAt!)),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
      actions: [
        TextButton(
          child: Text(
            success ? 'DONE' : 'TRY AGAIN',
            style: TextStyle(
              color: success ? _primaryColor : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
            if (!success) {
              cameraController.start();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ],
    ),
  );
}    


  Widget _buildVerificationDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      final parsedDate = DateTime.parse(dateTime);
      return DateFormat('MMM d, yyyy • hh:mm a').format(parsedDate);
    } catch (e) {
      return dateTime;
    }
  }

  Widget _buildScannerOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cutOutSize = size.width * 0.7;

    return Positioned.fill(
      child: Column(
        children: [
          Expanded(child: Container(color:  Colors.transparent)),
          Row(
            children: [
              Expanded(child: Container(color:  Colors.transparent)),
              Container(
                width: cutOutSize,
                height: cutOutSize,
                decoration: BoxDecoration(
                  border: Border.all(color: _primaryColor.withOpacity(0.5), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(top: 0, left: 0, child: _buildCornerIndicator(true, true)),
                    Positioned(top: 0, right: 0, child: _buildCornerIndicator(true, false)),
                    Positioned(bottom: 0, left: 0, child: _buildCornerIndicator(false, true)),
                    Positioned(bottom: 0, right: 0, child: _buildCornerIndicator(false, false)),
                  ],
                ),
              ),
              Expanded(child: Container(color:  Colors.transparent)),
            ],
          ),
          Expanded(
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(24),
              child: const Column(
                children: [
                  Text(
                    'Align the QR code within the frame',
                    style: TextStyle(color: _whiteColor, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Scanning will happen automatically',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerIndicator(bool isTop, bool isLeft) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: isLeft ? _primaryColor : Colors.transparent, width: 4),
          top: BorderSide(color: isTop ? _primaryColor : Colors.transparent, width: 4),
          right: BorderSide(color: !isLeft ? _primaryColor : Colors.transparent, width: 4),
          bottom: BorderSide(color: !isTop ? _primaryColor : Colors.transparent, width: 4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.transparent,
        foregroundColor: _whiteColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() {
                _isFlashOn = !_isFlashOn;
                cameraController.toggleTorch();
              });
            },
          ),
          IconButton(
            icon: Icon(_isFrontCamera ? Icons.camera_front : Icons.camera_rear),
            onPressed: () {
              setState(() {
                _isFrontCamera = !_isFrontCamera;
                cameraController.switchCamera();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  _verifyQRCode(barcode.rawValue!);
                  break; // Process only one code at a time
                }
              }
            },
          ),
          _buildScannerOverlay(context),
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}