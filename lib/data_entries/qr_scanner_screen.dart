import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:safenest/api/New_api.dart';

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

    setState(() => _isProcessing = true);

    try {
      final result = await ApiService.verifyQRCode(
        qrCode: qrCode,
        token: widget.token,
      );

      if (!mounted) return;

      _showVerificationSuccess(
        result['childName'] ?? 'Unknown',
        result['grade'] ?? 'N/A',
        result['verifiedAt'] ?? DateTime.now().toString(),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showVerificationSuccess(String childName, String grade, String verifiedAt) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Pickup Verified',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Child:', childName),
            const SizedBox(height: 12),
            _buildDetailRow('Grade:', grade),
            const SizedBox(height: 12),
            _buildDetailRow('Time:', _formatDateTime(verifiedAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              cameraController.start();
            },
            child: const Text(
              'SCAN NEXT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: _whiteColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _whiteColor,
            ),
            onPressed: () {
              setState(() => _isFlashOn = !_isFlashOn);
              cameraController.toggleTorch();
            },
          ),
          IconButton(
            icon: Icon(
              _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
              color: _whiteColor,
            ),
            onPressed: () {
              setState(() => _isFrontCamera = !_isFrontCamera);
              cameraController.switchCamera();
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
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
                color: Colors.transparent,
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

  Widget _buildScannerOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cutOutSize = size.width * 0.7;

    return Positioned.fill(
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.transparent,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Container(
                width: cutOutSize,
                height: cutOutSize,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Corner indicators
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _buildCornerIndicator(true, true),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _buildCornerIndicator(true, false),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: _buildCornerIndicator(false, true),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _buildCornerIndicator(false, false),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ],
          ),
          Expanded(
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(24),
              child: const Column(
                children: [
                  Text(
                    'Align the QR code within the frame',
                    style: TextStyle(
                      color: _whiteColor,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Scanning will happen automatically',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
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
          left: BorderSide(
            color: isLeft ? _primaryColor : Colors.transparent,
            width: 4,
          ),
          top: BorderSide(
            color: isTop ? _primaryColor : Colors.transparent,
            width: 4,
          ),
          right: BorderSide(
            color: !isLeft ? _primaryColor : Colors.transparent,
            width: 4,
          ),
          bottom: BorderSide(
            color: !isTop ? _primaryColor : Colors.transparent,
            width: 4,
          ),
        ),
      ),
    );
  }
}