import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/clockin_session_model.dart';
import '../models/worker_scan_model.dart';
import '../providers/clockin_provider.dart';
import 'clockin_scanner_page.dart';
import 'clockin_scanner_debug_page.dart';
import 'clockin_success_page.dart';
import 'clockin_setup_page.dart';

// Temporary localization class
class _TempLocalizations {
  static const clockingDashboard = 'Clock-In Dashboard';
  static const workersScanned = 'Workers Scanned';
  static const workersAbsent = 'Workers Absent';
  static const workersPending = 'Workers Pending';
  static const scanWorker = 'Scan Worker';
  static const finishClocking = 'Finish Clock-In';
  static const loading = 'Loading...';
}

class ClockinDashboardPage extends ConsumerStatefulWidget {
  final int contractId;

  const ClockinDashboardPage({
    super.key,
    required this.contractId,
  });

  @override
  ConsumerState<ClockinDashboardPage> createState() => _ClockinDashboardPageState();
}

class _ClockinDashboardPageState extends ConsumerState<ClockinDashboardPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inicializar sesión si no existe y cargar workers del servidor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(currentSessionProvider);
      if (session == null) {
        ref.read(clockinProvider.notifier).initializeSession(widget.contractId);
      }
      // Si no hay workday activo, redirigir a setup
      if (session?.workday == null || session!.workday!.isNotStarted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClockinSetupPage(
              contractId: widget.contractId,
            ),
          ),
        );
        return;
      }
      // Cargar workers presentes y ausentes del servidor
      ref.read(clockinProvider.notifier).refreshWorkerLists();
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
      // Refrescar la lista de workers cuando la app vuelve a estar activa
      ref.read(clockinProvider.notifier).refreshWorkerLists();
    }
  }

  Future<void> _showFinishConfirmationDialog() async {
    // Verificar si el supervisor ha hecho su propio clock-in
    final hasClockedIn = await ref.read(clockinProvider.notifier).checkSupervisorHasClockedIn();
    
    if (!hasClockedIn) {
      // Mostrar diálogo preguntando si quiere hacer su clock-in
      final wantsToClockin = await showDialog<bool>(
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
              const Expanded(child: Text('Your Clock-In')),
            ],
          ),
          content: const Text(
            'You haven\'t clocked in yet. Would you like to clock in before finishing the process?',
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
                'Yes, Clock In',
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

      if (wantsToClockin == true) {
        // Navegar al scanner para que el supervisor haga su clock-in
        // skipValidation: true para que no pida actualizar hora
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClockinScannerPage(
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
            const Text('Finish Clock-In'),
          ],
        ),
        content: const Text(
          'Are you sure you want to finish the clock-in process? This action cannot be undone.',
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
      await _handleFinishClockin();
    }
  }

  Future<void> _handleFinishClockin() async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await ref.read(clockinProvider.notifier).finishClockin();
      
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (result['success'] == true) {
        // Navegar a pantalla de éxito
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClockinSuccessPage(
              title: 'Clock-In Finished!',
              message: 'The clock-in process has been completed successfully.',
              onContinue: () {
                // Volver al dashboard principal
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
        );
      } else {
        // Mostrar error
        _showErrorDialog(result['error'] ?? 'Failed to finish clock-in');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
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

  @override
  Widget build(BuildContext context) {
    final clockinState = ref.watch(clockinProvider);
    final session = ref.watch(currentSessionProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          _TempLocalizations.clockingDashboard,
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Botón de DEBUG MODE
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            tooltip: 'Debug Mode',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClockinScannerDebugPage(
                    contractId: widget.contractId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(clockinState, session),
    );
  }

  Widget _buildBody(ClockinState clockinState, session) {
    if (clockinState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            const SizedBox(height: 16),
            const Text(_TempLocalizations.loading),
          ],
        ),
      );
    }

    if (clockinState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error: ${clockinState.error}',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(clockinProvider.notifier).initializeSession(widget.contractId);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (session == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('No active session found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
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
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textGrey,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Present (${session.scannedCount})'),
                    Tab(text: 'Absent (${session.totalWorkers - session.scannedCount})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildScannedWorkersList(session),
                      _buildAbsentWorkersList(session),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action Buttons - Mejor diseño
        _buildActionButtons(session),
      ],
    );
  }

  Widget _buildContractInfoCard(session) {
    final workday = session.workday;
    final isFinished = workday?.clockInEnd != null;
    
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
          // Indicador de proceso finalizado
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
                          'Clock-In Process Finished',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (workday?.clockInEnd != null)
                          Text(
                            'Finished at: ${_formatDateTime(workday!.clockInEnd!)}',
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
              // Información del contrato (lado izquierdo)
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
                    if (workday?.defaultEntryTime != null)
                      _buildInfoRow('Entry Time', _formatDateTime(workday!.defaultEntryTime!)),
                    _buildInfoRow('Total Workers', session.totalWorkers.toString()),
                    _buildInfoRow('Status', session.statusDisplayName),
                  ],
                ),
              ),
          
          // Botón Scan Worker (lado derecho) - Solo si NO está finalizado
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
                        builder: (context) => ClockinScannerPage(
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildStatsCards(session) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: _TempLocalizations.workersScanned,
            value: session.scannedCount.toString(),
            color: AppColors.success,
            icon: Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: _TempLocalizations.workersAbsent,
            value: session.absentCount.toString(),
            color: AppColors.warning,
            icon: Icons.cancel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: _TempLocalizations.workersPending,
            value: session.pendingCount.toString(),
            color: AppColors.info,
            icon: Icons.schedule,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkersSection(session) {
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
            'Workers Status',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Total Workers: ${session.totalWorkers}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Detailed worker lists will be implemented in the next sprint.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(session) {
    final isFinished = session.workday?.clockInEnd != null;
    
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
            // Finish Clocking Button (solo si NO está finalizado)
            if (!isFinished && session.canFinishSession)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showFinishConfirmationDialog(),
                  icon: Icon(Icons.check_circle, size: 20, color: AppColors.success),
                  label: Text(
                    'Finish Clock-In',
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
            
            // Untimely Clock-in Button (solo si YA está finalizado)
            if (isFinished)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClockinScannerPage(
                          contractId: widget.contractId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  label: Text(
                    'Untimely Clock-in',
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

  // Lista de workers presentes (escaneados)
  Widget _buildScannedWorkersList(session) {
    final scannedWorkers = session.scannedWorkers;
    
    if (scannedWorkers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textGrey),
            const SizedBox(height: 16),
            Text(
              'No hay trabajadores escaneados aún',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(clockinProvider.notifier).refreshWorkerLists();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: scannedWorkers.length,
        itemBuilder: (context, index) {
          final worker = scannedWorkers[index];
          return _buildWorkerCard(
            worker: worker,
            icon: Icons.check_circle,
            iconColor: AppColors.success,
            subtitle: worker.scannedAt != null 
                ? 'Entrada: ${_formatTime(worker.scannedAt!)}'
                : 'Escaneado',
          );
        },
      ),
    );
  }

  // Lista de workers ausentes (incluye pendientes y marcados como ausentes)
  Widget _buildAbsentWorkersList(session) {
    // Combinar workers ausentes marcados y pendientes
    final absentWorkers = session.absentWorkers;
    final pendingWorkers = session.pendingWorkers;
    final allAbsent = [...absentWorkers, ...pendingWorkers];
    
    if (allAbsent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              '¡Todos los trabajadores están presentes!',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(clockinProvider.notifier).refreshWorkerLists();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allAbsent.length,
        itemBuilder: (context, index) {
          final worker = allAbsent[index];
          final isMarkedAbsent = worker.status == WorkerStatus.absent;
          
          return _buildWorkerCard(
            worker: worker,
            icon: isMarkedAbsent ? Icons.cancel : Icons.pending,
            iconColor: isMarkedAbsent ? AppColors.error : AppColors.warning,
            subtitle: isMarkedAbsent 
                ? (worker.absenceReason?.description ?? 'Ausente')
                : 'Pendiente de escanear',
            trailing: !isMarkedAbsent ? IconButton(
              icon: Icon(Icons.person_off, color: AppColors.error),
              onPressed: () => _markWorkerAbsent(worker),
            ) : null,
          );
        },
      ),
    );
  }

  // Lista de workers pendientes
  Widget _buildPendingWorkersList(session) {
    final pendingWorkers = session.pendingWorkers;
    
    if (pendingWorkers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              '¡Todos los trabajadores han sido procesados!',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(clockinProvider.notifier).refreshWorkerLists();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingWorkers.length,
        itemBuilder: (context, index) {
          final worker = pendingWorkers[index];
          return _buildWorkerCard(
            worker: worker,
            icon: Icons.pending,
            iconColor: AppColors.warning,
            subtitle: 'Pendiente de escanear',
            trailing: IconButton(
              icon: Icon(Icons.person_off, color: AppColors.error),
              onPressed: () => _markWorkerAbsent(worker),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkerCard({
    required worker,
    required IconData icon,
    required Color iconColor,
    required String subtitle,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          '${worker.firstName} ${worker.lastName}',
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
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: iconColor,
              ),
            ),
          ],
        ),
        trailing: trailing,
        isThreeLine: true,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _markWorkerAbsent(worker) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como ausente'),
        content: Text('¿Marcar a ${worker.firstName} ${worker.lastName} como ausente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(clockinProvider.notifier).markWorkerAbsent(
                workerId: worker.id,
                reason: AbsenceReason.unjustified,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Marcar ausente'),
          ),
        ],
      ),
    );
  }
}
