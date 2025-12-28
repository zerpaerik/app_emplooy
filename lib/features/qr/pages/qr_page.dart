import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../user/providers/user_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

// Temporary localization class
class _TempLocalizations {
  static const qrCode = 'My QR Code';
  static const employeeId = 'BTN ID';
  static const personalInfo = 'Personal Information';
}

class QRPage extends ConsumerStatefulWidget {
  const QRPage({super.key});

  @override
  ConsumerState<QRPage> createState() => _QRPageState();
}

class _QRPageState extends ConsumerState<QRPage> {
  @override
  void initState() {
    super.initState();
    // Cargar información del contrato
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final user = userState.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          _TempLocalizations.qrCode,
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
          ),
        ),
     
      ),
      body: userState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // QR Code Section
                      _buildQRSection(user),
                      const SizedBox(height: 24),

                      // Personal Information with Contract
                      _buildPersonalInfo(user, dashboardState),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load user information',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(user, dashboardState) {
    final hasContract = user.contract > 0;
    final contract = dashboardState.currentContract;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contract Information
          const SizedBox(height: 20),
          Divider(color: AppColors.borderLight),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Icon(
                hasContract ? Icons.work : Icons.work_off_outlined,
                color: hasContract ? AppColors.primary : AppColors.textGrey,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                hasContract ? 'Current Contract' : 'Standing By',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (hasContract && contract != null) ...[
            _buildInfoRow(
              icon: Icons.business,
              label: 'Proyecto',
              value: contract['contract_name']?.toString() ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.location_city,
              label: 'Compañía',
              value: contract['contract_owner']?.toString() ?? 'N/A',
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.textGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.textGrey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No active contract - Looking for work opportunities',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQRSection(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // User Name and BTN ID
          Text(
            user.fullName,
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'BTN ID: ${user.btnId}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderLight,
                width: 2,
              ),
            ),
            child: QrImageView(
              data: user.btnId.isNotEmpty ? user.btnId : 'NO_ID_${user.id}',
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              gapless: true,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textGrey,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textGrey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

}
