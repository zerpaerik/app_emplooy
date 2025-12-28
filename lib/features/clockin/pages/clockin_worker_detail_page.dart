import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/clockin_provider.dart';
import '../services/location_service.dart';
import 'clockin_scanner_page.dart';

class ClockinWorkerDetailPage extends ConsumerStatefulWidget {
  final int contractId;
  final Map<String, dynamic> workerData;
  final String location;
  final String contractName;
  final String companyName;
  final String defaultEntryTime;

  const ClockinWorkerDetailPage({
    Key? key,
    required this.contractId,
    required this.workerData,
    required this.location,
    required this.contractName,
    required this.companyName,
    required this.defaultEntryTime,
  }) : super(key: key);

  @override
  ConsumerState<ClockinWorkerDetailPage> createState() => _ClockinWorkerDetailPageState();
}

class _ClockinWorkerDetailPageState extends ConsumerState<ClockinWorkerDetailPage> {
  bool _isProcessing = false;

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  String _getCurrentTime() {
    return DateFormat('hh:mm a').format(DateTime.now());
  }

  Future<void> _confirmClockIn() async {
    // Prevenir múltiples clicks
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Obtener workerId del workerData (ya verificado en scanner)
      final workerId = widget.workerData['id'] as int;
      final workerName = '${widget.workerData['first_name']} ${widget.workerData['last_name']}';

      // Registrar y esperar respuesta
      final result = await ref.read(clockinProvider.notifier).registerWorkerClockin(
        workerId: workerId,
        workerName: workerName,
        location: widget.location,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Navegar inmediatamente sin mostrar diálogo
        _navigateBackToScanner();
      } else {
        // Mostrar error si falla
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to register clock-in'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _navigateBackToScanner() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ClockinScannerPage(
          contractId: widget.contractId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.workerData['first_name'] ?? '';
    final lastName = widget.workerData['last_name'] ?? '';
    final btnId = widget.workerData['btn_id'] ?? '';
    final profileImage = widget.workerData['profile_image'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _navigateBackToScanner,
        ),
        title: Row(
          children: [
            Icon(Icons.login, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              'Clock-In Detail',
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contract Information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contractName,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.companyName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Worker Data
            Text(
              'Worker Data',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emplooy ID: $btnId',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Worker Name - Tappable to show photo
                  GestureDetector(
                    onTap: () {
                      if (profileImage.isNotEmpty) {
                        _showWorkerPhoto(firstName, lastName, profileImage);
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstName,
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                          ),
                        ),
                        Text(
                          lastName,
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Clock-In Time Information
            Text(
              'Clock-In Time',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Current Time
                  Row(
                    children: [
                      Icon(Icons.access_time, color: AppColors.textDark, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Current Time',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 36),
                      child: Text(
                        _getCurrentTime(),
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Registration Time
                  Row(
                    children: [
                      Icon(Icons.schedule, color: AppColors.textDark, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Registration Time',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 36),
                      child: Text(
                        _formatTime(widget.defaultEntryTime),
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _confirmClockIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Processing...',
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Accept',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkerPhoto(String firstName, String lastName, String profileImage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Picture of: $firstName $lastName',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                profileImage,
                height: 300,
                width: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    width: 300,
                    color: AppColors.backgroundLight,
                    child: Icon(
                      Icons.person,
                      size: 100,
                      color: AppColors.textGrey,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 300,
                    width: 300,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'OK',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
