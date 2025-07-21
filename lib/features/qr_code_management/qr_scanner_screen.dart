import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safenest/api_services/file.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _verifyQRCode(String qrCode) async {
    if (!mounted) return;

    setState(() => isVerifying = true);

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
        Navigator.pop(context, response);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR verification failed: ${_mapErrorToMessage(e)}')),
        );
        setState(() {
          isScanning = true; // Allow retry
          isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred')),
        );
        setState(() {
          isScanning = true; // Allow retry
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
        backgroundColor: const Color(0xFF5271FF),
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
          MobileScanner(
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
          if (isVerifying)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

