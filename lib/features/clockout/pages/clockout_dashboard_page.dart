import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/clockout_session_model.dart';
import '../models/worker_clockout_model.dart';
import '../providers/clockout_provider.dart';
import 'clockout_scanner_page.dart';
import 'clockout_success_page.dart';

class ClockoutDashboardPage extends ConsumerStatefulWidget {
  final int contractId;

  const ClockoutDashboardPage({
    Key? key,
    required this.contractId,
  }) : super(key: key);

  @override
  ConsumerState<ClockoutDashboardPage> createState() => _ClockoutDashboardPageState();
}

class _ClockoutDashboardPageState extends ConsumerState<ClockoutDashboardPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    
    // Inicializar o refrescar datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(currentClockoutSessionProvider);
      if (session == null) {
        ref.read(clockoutProvider.notifier).initializeSession(widget.contractId);
      } else {
        ref.read(clockoutProvider.notifier).refreshWorkerLists();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refrescar la lista de workers cuando la app vuelve a estar activa
      ref.read(clockoutProvider.notifier).refreshWorkerLists();
    }
  }

  Future<void> _showFinishConfirmationDialog() async {
    // Verificar si el supervisor ha hecho su propio clock-out
    final hasClockedOut = await ref.read(clockoutProvider.notifier).checkSupervisorHasClockedOut();
    
    if (!hasClockedOut) {
      // Mostrar diálogo preguntando si quiere hacer su clock-out
      final wantsToClockout = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              const Expanded(child: Text('Your Clock-Out')),
            ],
          ),
          content: const Text(
            'You haven\'t clocked out yet. Would you like to clock out before finishing the process?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'No, Finish Anyway',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Yes, Clock Out',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (wantsToClockout == true) {
        // Navegar al scanner para que el supervisor haga su clock-out
        // skipValidation: true para que no pida actualizar hora
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClockoutScannerPage(
              contractId: widget.contractId,
              skipValidation: true,
            ),
          ),
        );
        return;
      }
    }

    // Mostrar confirmación final
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            const Text('Finish Clock-Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to finish the clock-out process? This action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Yes, Finish',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _handleFinishClockout();
    }
  }

  Future<void> _handleFinishClockout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await ref.read(clockoutProvider.notifier).finishClockout();
      
      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClockoutSuccessPage(
              title: 'Clock-Out Finished!',
              message: 'The clock-out process has been completed successfully.',
              onContinue: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
        );
      } else {
        _showErrorDialog(result['error'] ?? 'Failed to finish clock-out');
      }
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
            onPressed: () => Navigator.of(ctx).pop(),
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

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '--:--';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final clockoutState = ref.watch(clockoutProvider);
    final session = ref.watch(currentClockoutSessionProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Clock-Out Dashboard',
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
      body: clockoutState.isLoading && session == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(session),
    );
  }

  Widget _buildBody(ClockoutSessionModel? session) {
    if (session == null) {
      return Center(
        child: Text(
          'No session data available',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textGrey,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Contract Info Card
        Padding(
          padding: const EdgeInsets.all(20),
          child: _buildContractInfoCard(session),
        ),

        // Tabs con listas de workers
        Expanded(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textGrey,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'Clocked Out (${session.clockedOutWorkers.length})'),
                  Tab(text: 'Pending (${session.pendingWorkers.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildClockedOutList(session),
                    _buildPendingList(session),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Action Buttons
        _buildActionButtons(session),
      ],
    );
  }

  Widget _buildContractInfoCard(ClockoutSessionModel session) {
    final workday = session.workday;
    final isFinished = workday?.clockOutEnd != null;
    
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
          if (isFinished)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clock-Out Process Finished',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (workday?.clockOutEnd != null)
                          Text(
                            'Finished at: ${_formatDateTime(workday!.clockOutEnd!)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textGrey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Contract Information',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Contract ID', session.contractId ?? 'N/A'),
                    if (workday?.defaultExitTime != null)
                      _buildInfoRow('Exit Time', _formatDateTime(workday!.defaultExitTime!)),
                    _buildInfoRow('Total Workers', session.totalWorkers.toString()),
                    _buildInfoRow('Status', session.statusDisplayName),
                  ],
                ),
              ),
              
              if (!isFinished) ...[
                const SizedBox(width: 16),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClockoutScannerPage(
                              contractId: widget.contractId,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 36,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Scan',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockedOutList(ClockoutSessionModel session) {
    final workers = session.clockedOutWorkers;

    if (workers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textGrey),
            const SizedBox(height: 16),
            Text(
              'No hay trabajadores con clock-out registrado',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(clockoutProvider.notifier).refreshWorkerLists(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: workers.length,
        itemBuilder: (context, index) {
          final worker = workers[index];
          return _buildWorkerCardWithClockout(worker);
        },
      ),
    );
  }

  Widget _buildWorkerCardWithClockout(WorkerClockoutModel worker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.success.withOpacity(0.1),
          child: Icon(Icons.check_circle, color: AppColors.success),
        ),
        title: Text(
          worker.fullName,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BTN ID: ${worker.btnId}',
              style: AppTextStyles.caption,
            ),
            if (worker.clockTime != null)
              Text(
                'Salida: ${_formatTime(worker.clockTime!)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildPendingList(ClockoutSessionModel session) {
    final workers = session.pendingWorkers;

    if (workers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textGrey),
            const SizedBox(height: 16),
            Text(
              'No hay trabajadores pendientes',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(clockoutProvider.notifier).refreshWorkerLists(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: workers.length,
        itemBuilder: (context, index) {
          final worker = workers[index];
          return _buildWorkerCardPending(worker);
        },
      ),
    );
  }

  Widget _buildWorkerCardPending(WorkerClockoutModel worker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.warning.withOpacity(0.1),
          child: Icon(Icons.pending, color: AppColors.warning),
        ),
        title: Text(
          worker.fullName,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BTN ID: ${worker.btnId}',
              style: AppTextStyles.caption,
            ),
            Text(
              'Pendiente de escanear',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildActionButtons(ClockoutSessionModel session) {
    final isFinished = session.workday?.clockOutEnd != null;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isFinished && session.canFinishSession)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showFinishConfirmationDialog(),
                  icon: Icon(Icons.check_circle, size: 20, color: AppColors.success),
                  label: Text(
                    'Finish Clock-Out',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.success, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            
            if (isFinished)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClockoutScannerPage(
                          contractId: widget.contractId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  label: Text(
                    'Untimely Clock-out',
                    style: AppTextStyles.button.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
