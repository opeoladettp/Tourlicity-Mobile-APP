import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../services/tour_service.dart';
import '../../models/tour.dart';
import '../../utils/logger.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  final TourService _tourService = TourService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: controller,
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isProcessing)
                    const CircularProgressIndicator()
                  else ...[
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 48,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Point your camera at a QR code to join a tour',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    
    if (!_isProcessing && barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        _processQRCode(barcode.rawValue!);
      }
    }
  }

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Stop camera while processing
      await controller.stop();
      
      Logger.info('Processing QR code: $qrData');
      
      // Extract join code from QR data
      String? joinCode;
      
      if (qrData.contains('join_code=')) {
        // Extract join code from URL parameter
        final uri = Uri.tryParse(qrData);
        joinCode = uri?.queryParameters['join_code'];
      } else if (qrData.length <= 10 && RegExp(r'^[A-Z0-9]+$').hasMatch(qrData)) {
        // Direct join code
        joinCode = qrData;
      }
      
      if (joinCode == null) {
        throw Exception('Invalid QR code format');
      }
      
      // Search for tour by join code
      final tour = await _tourService.searchTourByJoinCode(joinCode);
      
      if (mounted) {
        // Show tour details and registration option, with option to just return the code
        _showTourDetailsDialog(tour, joinCode);
      }
      
    } catch (e) {
      Logger.error('Failed to process QR code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process QR code: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        // Resume camera for another scan
        await controller.start();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showTourDetailsDialog(Tour tour, String joinCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tour.tourName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tour.description != null) ...[
              Text(tour.description!),
              const SizedBox(height: 16),
            ],
            if (tour.startDate != null && tour.endDate != null) ...[
              Text('Duration: ${tour.startDate!.toLocal().toString().split(' ')[0]} to ${tour.endDate!.toLocal().toString().split(' ')[0]}'),
              const SizedBox(height: 8),
            ],
            Text('Available spots: ${tour.remainingTourists}'),
            const SizedBox(height: 8),
            Text('Join Code: $joinCode'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.start();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Return just the join code to the previous screen
              Navigator.of(context).pop();
              Navigator.of(context).pop(joinCode);
            },
            child: const Text('Use Code'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _registerForTour(tour.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('Join Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _registerForTour(String tourId) async {
    try {
      await _tourService.registerForTour(tourId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully registered for tour!'),
            backgroundColor: Colors.green,
          ),
        );
        if (mounted) {
          context.pop(); // Go back to previous screen
        }
      }
    } catch (e) {
      Logger.error('Failed to register for tour: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        controller.start();
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}