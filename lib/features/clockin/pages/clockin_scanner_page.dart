import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/database_helper.dart';
import '../providers/clockin_provider.dart';
import '../services/location_service.dart';
import 'clockin_dashboard_page.dart';
import 'clockin_worker_detail_page.dart';
import 'clockin_update_time_page.dart';

class ClockinScannerPage extends ConsumerStatefulWidget {
  final int contractId;
  final bool skipValidation;

  const ClockinScannerPage({
    Key? key,
    required this.contractId,
    this.skipValidation = false,
  }) : super(key: key);

  @override
  ConsumerState<ClockinScannerPage> createState() => _ClockinScannerPageState();
}

class _ClockinScannerPageState extends ConsumerState<ClockinScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;
  bool isScanning = false;
  Timer? scanDebouncer;
  Timer? countdownTimer;
  int remainingSeconds = 60; // 1 minuto como en Worker
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _validateBeforeScanning();
  }

  Future<void> _validateBeforeScanning() async {
    // Si skipValidation es true, saltar la validación y permitir escanear directamente
    if (widget.skipValidation) {
      _startCountdownTimer();
      return;
    }

    try {
      final validation = await ref.read(clockinProvider.notifier).validateBeforeScan();
      
      if (validation.shouldUpdate) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClockinUpdateTimePage(
              timeDifference: validation.timeDifference!,
              lastSupervisorId: validation.lastSupervisorId,
              lastScanTime: validation.lastScanTime,
            ),
          ),
        );
      } else {
        _startCountdownTimer();
      }
    } catch (e) {
      print('Error validating before scan: $e');
      _startCountdownTimer();
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    scanDebouncer?.cancel();
    controller?.dispose();
    super.dispose();
  }

  void _startCountdownTimer() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        _navigateBackToDashboard();
      }
    });
  }

  void _navigateBackToDashboard() {
    countdownTimer?.cancel();
    controller?.stopCamera();
    controller?.dispose();
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClockinDashboardPage(
            contractId: widget.contractId,
          ),
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    
    controller.scannedDataStream.listen((scanData) async {
      if (!isScanning && !isProcessing) {
        final qrCode = scanData.code;
        if (qrCode != null && qrCode.isNotEmpty) {
          setState(() {
            isScanning = true;
          });
          
          // Debouncing para evitar múltiples escaneos
          scanDebouncer?.cancel();
          scanDebouncer = Timer(const Duration(milliseconds: 500), () async {
            if (!isProcessing) {
              await _processQRCode(qrCode);
            }
          });
        }
      }
    });
  }

  Future<void> _processQRCode(String qrCode) async {
    if (isProcessing) return;
    
    setState(() {
      isProcessing = true;
    });

    try {
      // Pausar cámara durante procesamiento
      await controller?.pauseCamera();

      // Obtener ubicación (usar coordenadas por defecto si falla)
      final location = await _locationService.getCurrentLocation();
      final locationString = location != null 
          ? '${location.latitude} ${location.longitude}'
          : '18.4655 -66.1057'; // San Juan, PR por defecto

      // Verificar worker con el API (sin registrar aún)
      final session = ref.read(clockinProvider).session;
      if (session == null) {
        await _showErrorDialog('No active session found');
        setState(() {
          isProcessing = false;
          isScanning = false;
        });
        await controller?.resumeCamera();
        return;
      }
      
      // Si no hay workday activo, redirigir al dashboard para iniciar jornada
      if (session.workday == null) {
        print('Clock-In not finished -> Go to Clock-In Dashboard');
        _navigateBackToDashboard();
        return;
      }

      final contractId = int.tryParse(session.contractId ?? '0') ?? 0;
      
      // Verificar worker
      final verifyResult = await ref.read(clockinApiServiceProvider).verifyWorkerQR(
        identification: qrCode,
        contractId: contractId,
      );

      if (!mounted) return;

      if (verifyResult['success'] != true) {
        // Manejar errores de verificación
        final error = verifyResult['error'] ?? '';
        final data = verifyResult['data'] ?? {};
        final code = data['code']?.toString() ?? '';
        final detail = data['detail']?.toString() ?? '';

        String errorMessage = 'Unknown error';
        
        if (code == 'already clock in' || detail == 'The worker has already clocked-in') {
          errorMessage = 'QR ALREADY SCANNED';
        } else if (code == 'not_match_contract') {
          errorMessage = 'This user is registered with another company at this location';
        } else if (detail == 'worker not belongs to a project') {
          errorMessage = 'The worker is not in the contract';
        } else if (detail == 'Not found.') {
          errorMessage = 'Worker not found';
        } else if (error.isNotEmpty) {
          errorMessage = error;
        }

        await _showErrorDialog(errorMessage);
        setState(() {
          isProcessing = false;
          isScanning = false;
        });
        await controller?.resumeCamera();
        return;
      }

      // Worker verificado - Navegar a pantalla de detalle
      final workerData = verifyResult['data'];
      
      // CRÍTICO: Obtener defaultEntryTime actualizado de BD local
      // NO usar session.workday.defaultEntryTime (hora inicial)
      final workdayOn = await DatabaseHelper.getWorkdayOn();
      final defaultEntryTime = workdayOn != null && workdayOn['default_init'] != null
          ? workdayOn['default_init'] as String
          : DateTime.now().toIso8601String();
      
      print('📋 Navigating to detail with defaultEntryTime: $defaultEntryTime');
      
      // Detener cámara y timer
      countdownTimer?.cancel();
      controller?.stopCamera();
      controller?.dispose();

      // Navegar a pantalla de detalle con hora actualizada
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClockinWorkerDetailPage(
            contractId: widget.contractId,
            workerData: workerData,
            location: locationString,
            contractName: workerData['contract_name'] ?? 'Contract',
            companyName: workerData['company_name'] ?? 'Company',
            defaultEntryTime: defaultEntryTime,  // Usar hora actualizada de BD local
          ),
        ),
      );
    } catch (e) {
      print('Error processing QR: $e');
      if (mounted) {
        await _showErrorDialog('Error processing QR code');
        setState(() {
          isProcessing = false;
          isScanning = false;
        });
        await controller?.resumeCamera();
      }
    }
  }

  Future<void> _showSuccessDialog(String workerName) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 32),
            const SizedBox(width: 12),
            const Text('Success'),
          ],
        ),
        content: Text(
          'Worker $workerName has been clocked in successfully',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text(
              'OK',
              style: AppTextStyles.button.copyWith(
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error, size: 32),
            const SizedBox(width: 12),
            const Text('Error'),
          ],
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text(
              'OK',
              style: AppTextStyles.button.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
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
          onPressed: _navigateBackToDashboard,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.yellow),
            onPressed: () {
              controller?.toggleFlash();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Countdown Timer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: remainingSeconds <= 10 
                ? AppColors.error.withOpacity(0.9)
                : AppColors.primary,
            child: Center(
              child: Text(
                'Time remaining: ${_formatTime(remainingSeconds)}',
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
}
