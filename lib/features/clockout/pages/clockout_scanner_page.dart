import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/database_helper.dart';
import '../providers/clockout_provider.dart';
import '../../clockin/services/location_service.dart';
import '../../clockin/providers/clockin_provider.dart' show locationServiceProvider;
import 'clockout_worker_detail_page.dart';
import 'clockout_update_time_page.dart';

class ClockoutScannerPage extends ConsumerStatefulWidget {
  final int contractId;
  final bool skipValidation;

  const ClockoutScannerPage({
    Key? key,
    required this.contractId,
    this.skipValidation = false,
  }) : super(key: key);

  @override
  ConsumerState<ClockoutScannerPage> createState() => _ClockoutScannerPageState();
}

class _ClockoutScannerPageState extends ConsumerState<ClockoutScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;
  bool isScanning = true;
  int countdown = 60;
  Timer? countdownTimer;
  bool flashOn = false;

  @override
  void initState() {
    super.initState();
    _validateBeforeScanning();
  }

  Future<void> _validateBeforeScanning() async {
    // Si skipValidation es true, saltar la validación y permitir escanear directamente
    if (widget.skipValidation) {
      _startCountdown();
      return;
    }

    try {
      final validation = await ref.read(clockoutProvider.notifier).validateBeforeScan();
      
      if (validation.shouldUpdate) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ClockoutUpdateTimePage(
                timeDifference: validation.timeDifference!,
                lastSupervisorId: validation.lastSupervisorId,
                lastScanTime: validation.lastScanTime,
              ),
            ),
          );
        }
      } else {
        _startCountdown();
      }
    } catch (e) {
      print('Error validating before scan: $e');
      _startCountdown();
    }
  }

  void _startCountdown() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (countdown > 0) {
            countdown--;
          } else {
            timer.cancel();
            if (mounted) {
              Navigator.pop(context);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (isScanning && !isProcessing && scanData.code != null) {
        _processQRCode(scanData.code!);
      }
    });
  }

  Future<void> _processQRCode(String qrCode) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      await controller?.pauseCamera();

      final locationService = ref.read(locationServiceProvider);
      final location = await locationService.getCurrentLocation();
      final locationString = location != null 
          ? '${location.latitude} ${location.longitude}' 
          : '18.4655 -66.1057'; // San Juan, PR por defecto

      final session = ref.read(currentClockoutSessionProvider);
      if (session == null || session.workday == null) {
        await _showErrorDialog('No active workday found');
        setState(() {
          isProcessing = false;
          isScanning = false;
        });
        await controller?.resumeCamera();
        return;
      }

      final contractId = int.tryParse(session.contractId ?? '0') ?? 0;

      final verifyResult = await ref.read(clockoutProvider.notifier).scanWorkerQR(
        identification: qrCode,
        location: locationString,
      );

      if (!mounted) return;

      if (verifyResult['success'] != true) {
        String errorMessage = 'Failed to verify worker';
        
        if (verifyResult['error'] == 'QR ALREADY SCANNED') {
          errorMessage = 'This worker has already clocked out';
        } else if (verifyResult['error'] == 'NO CLOCK IN') {
          errorMessage = 'This worker has not clocked in yet';
        } else if (verifyResult['error'] == 'WORKER NOT IN CONTRACT') {
          errorMessage = 'This worker does not belong to this contract';
        } else if (verifyResult['error'] == 'WORKER NOT FOUND') {
          errorMessage = 'Worker not found in the system';
        } else if (verifyResult['message'] != null) {
          errorMessage = verifyResult['message'];
        }

        await _showErrorDialog(errorMessage);
        setState(() {
          isProcessing = false;
          isScanning = false;
        });
        await controller?.resumeCamera();
        return;
      }

      final workerData = verifyResult['data'];

      countdownTimer?.cancel();
      // CRÍTICO: Obtener defaultExitTime actualizado de BD local
      final workdayOn = await DatabaseHelper.getWorkdayOn();
      final defaultExitTime = workdayOn != null && workdayOn['default_exit'] != null
          ? workdayOn['default_exit'] as String
          : DateTime.now().toIso8601String();
      
      print('📋 Navigating to detail with defaultExitTime: $defaultExitTime');
      
      controller?.stopCamera();
      controller?.dispose();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClockoutWorkerDetailPage(
            contractId: widget.contractId,
            workerData: workerData,
            location: locationString,
            contractName: workerData['contract_name'] ?? 'Contract',
            companyName: workerData['company_name'] ?? 'Company',
            defaultExitTime: defaultExitTime,  // Usar hora actualizada de BD local
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        await _showErrorDialog('Error processing QR: $e');
        setState(() {
          isProcessing = false;
          isScanning = false;
        });
        await controller?.resumeCamera();
      }
    }
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            const Text('Error'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                isScanning = true;
              });
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFlash() async {
    if (controller != null) {
      await controller!.toggleFlash();
      setState(() {
        flashOn = !flashOn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Scan Worker QR',
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              flashOn ? Icons.flash_on : Icons.flash_off,
              color: flashOn ? Colors.yellow : Colors.white,
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Column(
        children: [
          // Countdown Timer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: countdown <= 10 
                ? AppColors.error.withOpacity(0.9)
                : AppColors.primary,
            child: Center(
              child: Text(
                'Time remaining: ${_formatTime(countdown)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          // QR Scanner
          Expanded(
            child: Stack(
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: AppColors.primary,
                    borderRadius: 16,
                    borderLength: 150,
                    borderWidth: 8,
                    cutOutSize: 300,
                    overlayColor: Colors.black.withOpacity(0.8),
                  ),
                ),
                
                // Processing Overlay
                if (isProcessing)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Processing QR...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black87,
            child: SafeArea(
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Position the QR code within the frame',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The scanner will automatically detect the code',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
