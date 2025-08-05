import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safenest/api/New_api.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanning = true;
  bool isTorchOn = false;
  bool isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    requestCameraPermission();
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted && mounted) {
        setState(() => _errorMessage = 'Camera permission denied');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Camera permission denied'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: requestCameraPermission,
            ),
          ),
        );
      }
    }
  }

  Future<void> _verifyQRCode(String qrCode) async {
    if (!mounted) return;

    setState(() {
      isVerifying = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.safeApiCall(
        () => ApiService.verifyQRCode(qrCode),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pickup verified for ${response['childName'] ?? 'child'} by ${response['parentName'] ?? 'parent'}',
            ),
          ),
        );
        Navigator.pop(context, qrCode); // Return qrCode to match TeacherDashboard
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _mapErrorToMessage(e));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR verification failed: $_errorMessage'),
            action: e.message == 'Network error'
                ? SnackBarAction(label: 'Retry', onPressed: () => _verifyQRCode(qrCode))
                : null,
          ),
        );
        setState(() {
          isScanning = true;
          isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'An unexpected error occurred');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred'),
            action: SnackBarAction(label: 'Retry', onPressed: () => _verifyQRCode(qrCode)),
          ),
        );
        setState(() {
          isScanning = true;
          isVerifying = false;
        });
      }
    }
  }

  String _mapErrorToMessage(ApiException e) {
    switch (e.message) {
      case 'Invalid QR code':
        return 'The scanned QR code is invalid';
      case 'Network error':
        return 'Please check your internet connection';
      case 'Unauthorized':
        return 'Please log in again';
      case 'Child not found':
        return 'Child not found for this QR code';
      default:
        return e.message;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5271FF),
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
        centerTitle: true,
        backgroundColor: const Color(0xFF5271FF),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/teacher_dashboard'),
        ),
        actions: [
          IconButton(
            icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              controller.toggleTorch();
              setState(() => isTorchOn = !isTorchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              Center(child: Image.asset('assets/safenest.png', height: 120)),
              const SizedBox(height: 20),
              Expanded(
                child: MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    final Barcode? firstBarcode = barcodes.isNotEmpty ? barcodes.first : null;

                    if (firstBarcode != null && firstBarcode.rawValue != null && isScanning && !isVerifying) {
                      setState(() => isScanning = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('QR code scanned successfully')),
                        );
                        _verifyQRCode(firstBarcode.rawValue!);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          if (isVerifying)
            const ModalBarrier(
              dismissible: false,
              color: Colors.black54,
            ),
          if (isVerifying)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (_errorMessage != null)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Material(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
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
    );
  }
}