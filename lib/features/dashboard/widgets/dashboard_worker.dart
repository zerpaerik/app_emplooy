import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/dashboard_provider.dart';
import '../../clockin/providers/clockin_provider.dart';
import '../../clockin/pages/clockin_setup_page.dart';
import '../../clockout/providers/clockout_provider.dart';
import '../../clockout/pages/clockout_setup_page.dart';
import '../../user/providers/user_provider.dart';
import '../../user/models/user_model.dart';
import '../../workday_reports/pages/workday_report_form_page.dart';

class DashboardWorker extends ConsumerStatefulWidget {
  const DashboardWorker({super.key});

  @override
  ConsumerState<DashboardWorker> createState() => _DashboardWorkerState();
}

class _DashboardWorkerState extends ConsumerState<DashboardWorker> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cargar datos del dashboard al iniciar
    Future.microtask(() async {
      ref.read(dashboardProvider.notifier).loadDashboardData();
      
      // Inicializar sesión de clock-in para obtener workday actual
      final user = ref.read(userProvider).user;
      if (user != null && user.contract != 0) {
        await ref.read(clockinProvider.notifier).initializeSession(user.contract);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refrescar el workday cuando la app vuelve a estar activa
      _refreshWorkdayState();
    }
  }

  Future<void> _refreshWorkdayState() async {
    final user = ref.read(userProvider).user;
    if (user != null && user.contract != 0) {
      await ref.read(clockinProvider.notifier).initializeSession(user.contract);
    }
  }

  String _getHourValue(Map<String, dynamic>? hours, String key) {
    if (hours == null) return '0';
    final value = hours[key];
    if (value == null) return '0';
    return value.toString();
  }

  Future<void> _handleClockInNavigation(UserModel? user) async {
    if (user == null || user.contract == 0) {
      _showErrorDialog('No contract found for user');
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Inicializar sesión para obtener workday actual
      await ref.read(clockinProvider.notifier).initializeSession(user.contract);
      
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      // Navegar al Setup Page y refrescar al regresar
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClockinSetupPage(
              contractId: user.contract,
            ),
          ),
        );
        
        // Refrescar el estado del workday al regresar
        if (mounted) {
          await _refreshWorkdayState();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        _showErrorDialog('Error: $e');
      }
    }
  }

  Future<void> _handleClockOutNavigation(UserModel? user) async {
    if (user == null || user.contract == 0) {
      _showErrorDialog('No contract found for user');
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Inicializar sesión para obtener workday actual
      await ref.read(clockoutProvider.notifier).initializeSession(user.contract);
      
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      final clockoutState = ref.read(clockoutProvider);

      if (clockoutState.error == 'CLOCK_IN_NOT_FINISHED') {
        _showErrorDialog('You must finish the Clock-In process before starting Clock-Out.');
        return;
      }

      if (clockoutState.error != null) {
        _showErrorDialog('Error: ${clockoutState.error}');
        return;
      }

      // Navegar al Setup Page y refrescar al regresar
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClockoutSetupPage(
            contractId: user.contract,
          ),
        ),
      );
      
      // Refrescar el estado del workday al regresar
      if (mounted) {
        await _refreshWorkdayState();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog('Error: $e');
      }
    }
  }

  Future<void> _handleWorkdayReportNavigation(UserModel? user) async {
    if (user == null || user.contract == 0) {
      _showErrorDialog('No contract found for user');
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Inicializar sesión para obtener workday actual
      await ref.read(clockinProvider.notifier).initializeSession(user.contract);
      
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      final clockinState = ref.read(clockinProvider);
      final workday = clockinState.session?.workday;

      if (workday == null || workday.id == null) {
        _showErrorDialog('No workday found');
        return;
      }

      // Navegar al formulario de workday report
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkdayReportFormPage(
            workdayId: workday.id!,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog('Error: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final userState = ref.watch(userProvider);
    final user = userState.user;

    if (dashboardState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dashboardProvider.notifier).loadDashboardData();
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contract Status Card
            _buildContractCard(dashboardState),
            const SizedBox(height: 16),

            // Total Hours Worked Section
            _buildTotalHoursSection(dashboardState),
            const SizedBox(height: 16),

            // Rank Time Section
            _buildRankTimeSection(dashboardState),
            const SizedBox(height: 16),

            // Ready to Work Card
            _buildReadyToWorkCard(user),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContractCard(DashboardState dashboardState) {
    final hasContract = dashboardState.contractStatusCode == 200;
    final contract = dashboardState.currentContract;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: hasContract 
              ? AppColors.primaryGradient
              : LinearGradient(
                  colors: [
                    AppColors.textGrey.withValues(alpha: 0.1),
                    AppColors.textGrey.withValues(alpha: 0.05),
                  ],
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasContract ? Icons.work : Icons.work_off_outlined,
                  color: hasContract ? Colors.white : AppColors.textGrey,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  hasContract ? 'Current Contract' : 'Standing By',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: hasContract ? Colors.white : AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasContract && contract != null) ...[
              Text(
                contract['contract_name'] ?? 'Contract',
                style: AppTextStyles.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                contract['contract_owner']?.toString() ?? 'Company',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ] else ...[
              Text(
                'No active contract',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Looking for work opportunities',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalHoursSection(DashboardState dashboardState) {
    final hours = dashboardState.workedHours;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Hours Worked',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildHourMetric(
                    value: _getHourValue(hours, 'regular_hours_worked'),
                    label: 'Regular',
                    icon: Icons.access_time,
                  ),
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: AppColors.textGrey.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildHourMetric(
                    value: _getHourValue(hours, 'extra_hours_worked'),
                    label: 'Overtime',
                    icon: Icons.timer,
                  ),
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: AppColors.textGrey.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildHourMetric(
                    value: _getHourValue(hours, 'total_travel_hours'),
                    label: 'Traveling',
                    icon: Icons.directions_car,
                  ),
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: AppColors.textGrey.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildHourMetric(
                    value: _getHourValue(hours, 'total_standby_hours'),
                    label: 'Stand-by',
                    icon: Icons.pause_circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourMetric({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRankTimeSection(DashboardState dashboardState) {
    final hours = dashboardState.workedHours;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rank Time',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTimeRankMetric(
                    value: _getHourValue(hours, 'worked_hours_yesterday'),
                    label: 'Yesterday',
                    icon: Icons.today,
                  ),
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: AppColors.textGrey.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildTimeRankMetric(
                    value: _getHourValue(hours, 'hours_last_week'),
                    label: 'Last 7 days',
                    icon: Icons.date_range,
                  ),
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: AppColors.textGrey.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildTimeRankMetric(
                    value: _getHourValue(hours, 'monthly_hours'),
                    label: 'Monthly',
                    icon: Icons.calendar_month,
                  ),
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: AppColors.textGrey.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildTimeRankMetric(
                    value: _getHourValue(hours, 'annual_hours'),
                    label: 'Annual',
                    icon: Icons.calendar_today,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Hours are confirmed after supervisor approval',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRankMetric({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadyToWorkCard(UserModel? user) {
    final clockinState = ref.watch(clockinProvider);
    final workday = clockinState.session?.workday;
    // Verificar que el workday existe Y no está en estado notStarted
    final hasActiveWorkday = workday != null && !workday.isNotStarted;
    final supervisorHasClockin = clockinState.session?.supervisorHasClockin ?? false;
    final clockInFinished = workday?.clockInEnd != null;
    final clockOutStarted = workday?.clockOutStart != null;
    final clockOutFinished = workday?.clockOutEnd != null;

    String statusText;
    String actionText;
    Color statusColor;
    bool isClockOut = false;
    bool isWorkdayReport = false;

    // VALIDACIÓN SEGÚN ESTADO DEL WORKDAY:
    
    if (hasActiveWorkday && clockOutFinished) {
      // Clock-Out finalizado -> Gestionar Workday Report
      statusText = 'Workday Completed';
      actionText = 'Manage Report';
      statusColor = AppColors.success;
      isWorkdayReport = true;
    } else if (hasActiveWorkday && clockOutStarted) {
      // Clock-Out en proceso -> Finalizar Clock-Out
      statusText = 'Clock-Out in Progress';
      actionText = 'Finish Clock-Out';
      statusColor = AppColors.warning;
      isClockOut = true;
    } else if (hasActiveWorkday && clockInFinished) {
      // Clock-In finalizado, Clock-Out no iniciado -> Iniciar Clock-Out
      statusText = 'Clock-In Finished';
      actionText = 'Start Clock-Out';
      statusColor = AppColors.error;
      isClockOut = true;
    } else if (hasActiveWorkday && supervisorHasClockin) {
      // Clock-In en proceso, supervisor ya hizo clock-in
      statusText = 'Currently Working';
      actionText = 'Go to Dashboard';
      statusColor = AppColors.success;
    } else if (hasActiveWorkday && !supervisorHasClockin) {
      // Workday activo pero supervisor no ha hecho clock-in
      statusText = 'Workday Active';
      actionText = 'Clock In';
      statusColor = AppColors.warning;
    } else {
      // Sin workday activo
      statusText = 'Ready to Work';
      actionText = 'Start Clock-in';
      statusColor = AppColors.primary;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isWorkdayReport
                        ? 'Tap to manage workday report'
                        : isClockOut
                            ? 'Tap to continue clock-out process'
                            : hasActiveWorkday 
                                ? 'Tap to continue your workday'
                                : 'Tap to start your workday',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () => isWorkdayReport
                  ? _handleWorkdayReportNavigation(user)
                  : isClockOut 
                      ? _handleClockOutNavigation(user)
                      : _handleClockInNavigation(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                actionText,
                style: AppTextStyles.button,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
