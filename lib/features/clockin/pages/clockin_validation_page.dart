import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/clockin_provider.dart';
import '../models/clockin_session_model.dart';
import 'clockin_setup_page.dart';
import 'clockin_dashboard_page.dart';

// Temporary localization class
class _TempLocalizations {
  static const clockIn = 'Clock In';
  static const validatingWorkday = 'Validating Workday...';
  static const workdayNotStarted = 'Workday Not Started';
  static const workdaySetupRequired = 'Setup Required';
  static const workdayActive = 'Workday Active';
  static const workdayFinished = 'Workday Finished';
  static const setupWorkday = 'Setup Workday';
  static const continueClocking = 'Continue Clock-In';
  static const viewResults = 'View Results';
  static const startNewWorkday = 'Start New Workday';
  static const noWorkdayMessage = 'No workday has been started for today. You need to configure the workday settings before starting the clock-in process.';
  static const setupRequiredMessage = 'The workday has been configured but the clock-in process hasn\'t started yet. You can continue with the setup.';
  static const activeWorkdayMessage = 'The clock-in process is currently active. You can continue scanning workers or manage the session.';
  static const finishedWorkdayMessage = 'The workday clock-in process has been completed. You can view the results or start a new workday.';
  static const error = 'Error';
  static const retry = 'Retry';
}

class ClockinValidationPage extends ConsumerStatefulWidget {
  final int contractId;

  const ClockinValidationPage({
    super.key,
    required this.contractId,
  });

  @override
  ConsumerState<ClockinValidationPage> createState() => _ClockinValidationPageState();
}

class _ClockinValidationPageState extends ConsumerState<ClockinValidationPage> {
  @override
  void initState() {
    super.initState();
    // Inicializar la sesión al cargar la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clockinProvider.notifier).initializeSession(widget.contractId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final clockinState = ref.watch(clockinProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          _TempLocalizations.clockIn,
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(clockinState),
    );
  }

  Widget _buildBody(ClockinState clockinState) {
    if (clockinState.isLoading) {
      return _buildLoadingState();
    }

    if (clockinState.error != null) {
      return _buildErrorState(clockinState.error!);
    }

    if (clockinState.session == null) {
      return _buildNoSessionState();
    }

    return _buildValidationContent(clockinState.session!);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            _TempLocalizations.validatingWorkday,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 20),
            Text(
              _TempLocalizations.error,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ref.read(clockinProvider.notifier).initializeSession(widget.contractId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _TempLocalizations.retry,
                style: AppTextStyles.button.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSessionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 64,
              color: AppColors.textGrey,
            ),
            const SizedBox(height: 20),
            Text(
              'No Session Available',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Unable to load workday information. Please try again.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationContent(ClockinSessionModel session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Status Card
          _buildStatusCard(session),
          const SizedBox(height: 30),

          // Action Buttons
          _buildActionButtons(session),
          const SizedBox(height: 30),

          // Session Info
          if (session.workday != null) _buildWorkdayInfo(session),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ClockinSessionModel session) {
    final statusInfo = _getStatusInfo(session.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (statusInfo['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              statusInfo['icon'],
              size: 48,
              color: statusInfo['color'],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            statusInfo['title'],
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            statusInfo['description'],
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ClockinSessionModel session) {
    final actionInfo = _getActionInfo(session.status);

    return Column(
      children: actionInfo.map<Widget>((action) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton(
            onPressed: () => _handleAction(action['action'], session),
            style: ElevatedButton.styleFrom(
              backgroundColor: action['isPrimary'] ? AppColors.primary : Colors.white,
              foregroundColor: action['isPrimary'] ? Colors.white : AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: action['isPrimary'] 
                    ? BorderSide.none 
                    : BorderSide(color: AppColors.primary),
              ),
              elevation: action['isPrimary'] ? 2 : 0,
            ),
            child: Text(
              action['label'],
              style: AppTextStyles.button.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkdayInfo(ClockinSessionModel session) {
    final workday = session.workday!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workday Information',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Contract ID', workday.contractId.toString()),
          if (workday.defaultEntryTime != null)
            _buildInfoRow('Entry Time', _formatDateTime(workday.defaultEntryTime!)),
          if (workday.temperature != null)
            _buildInfoRow('Temperature', '${workday.temperature}°F'),
          if (session.totalWorkers > 0)
            _buildInfoRow('Total Workers', session.totalWorkers.toString()),
          if (session.isActive) ...[
            _buildInfoRow('Scanned', session.scannedCount.toString()),
            _buildInfoRow('Absent', session.absentCount.toString()),
            _buildInfoRow('Pending', session.pendingCount.toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(ClockinStatus status) {
    switch (status) {
      case ClockinStatus.notStarted:
        return {
          'title': _TempLocalizations.workdayNotStarted,
          'description': _TempLocalizations.noWorkdayMessage,
          'icon': Icons.schedule,
          'color': AppColors.warning,
        };
      case ClockinStatus.setup:
        return {
          'title': _TempLocalizations.workdaySetupRequired,
          'description': _TempLocalizations.setupRequiredMessage,
          'icon': Icons.settings,
          'color': AppColors.info,
        };
      case ClockinStatus.active:
        return {
          'title': _TempLocalizations.workdayActive,
          'description': _TempLocalizations.activeWorkdayMessage,
          'icon': Icons.play_circle,
          'color': AppColors.success,
        };
      case ClockinStatus.finished:
        return {
          'title': _TempLocalizations.workdayFinished,
          'description': _TempLocalizations.finishedWorkdayMessage,
          'icon': Icons.check_circle,
          'color': AppColors.success,
        };
    }
  }

  List<Map<String, dynamic>> _getActionInfo(ClockinStatus status) {
    switch (status) {
      case ClockinStatus.notStarted:
        return [
          {
            'label': _TempLocalizations.setupWorkday,
            'action': 'setup',
            'isPrimary': true,
          },
        ];
      case ClockinStatus.setup:
        return [
          {
            'label': _TempLocalizations.continueClocking,
            'action': 'continue',
            'isPrimary': true,
          },
          {
            'label': _TempLocalizations.setupWorkday,
            'action': 'setup',
            'isPrimary': false,
          },
        ];
      case ClockinStatus.active:
        return [
          {
            'label': _TempLocalizations.continueClocking,
            'action': 'continue',
            'isPrimary': true,
          },
        ];
      case ClockinStatus.finished:
        return [
          {
            'label': _TempLocalizations.viewResults,
            'action': 'results',
            'isPrimary': true,
          },
          {
            'label': _TempLocalizations.startNewWorkday,
            'action': 'new',
            'isPrimary': false,
          },
        ];
    }
  }

  void _handleAction(String action, ClockinSessionModel session) {
    switch (action) {
      case 'setup':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClockinSetupPage(
              contractId: widget.contractId,
              existingWorkday: session.workday,
            ),
          ),
        );
        break;
      case 'continue':
      case 'results':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClockinDashboardPage(
              contractId: widget.contractId,
            ),
          ),
        );
        break;
      case 'new':
        // Reset session and go to setup
        ref.read(clockinProvider.notifier).resetSession();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClockinSetupPage(
              contractId: widget.contractId,
            ),
          ),
        );
        break;
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
