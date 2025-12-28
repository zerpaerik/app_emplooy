import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/database_helper.dart';
import '../providers/clockin_provider.dart';
import 'clockin_dashboard_page.dart';
import 'clockin_update_time_page.dart';

class ClockinScannerDebugPage extends ConsumerStatefulWidget {
  final int contractId;
  final bool skipValidation;

  const ClockinScannerDebugPage({
    Key? key,
    required this.contractId,
    this.skipValidation = false,
  }) : super(key: key);

  @override
  ConsumerState<ClockinScannerDebugPage> createState() => _ClockinScannerDebugPageState();
}

class _ClockinScannerDebugPageState extends ConsumerState<ClockinScannerDebugPage> {
  bool isProcessing = false;
  Timer? countdownTimer;
  int remainingSeconds = 60;
  String debugLog = '';

  // BTN IDs hardcodeados para testing
  final List<Map<String, String>> debugWorkers = [
    {'btnId': '910360', 'name': 'Worker Test 1'},
    {'btnId': '725190', 'name': 'Worker Test 2'},
  ];

  @override
  void initState() {
    super.initState();
    _validateBeforeScanning();
  }

  Future<void> _validateBeforeScanning() async {
    if (widget.skipValidation) {
      _addLog('⏭️ Skipping validation (skipValidation=true)');
      _startCountdownTimer();
      return;
    }

    try {
      _addLog('🔍 Starting validation...');
      final validation = await ref.read(clockinProvider.notifier).validateBeforeScan();
      
      _addLog('📊 Validation result:');
      _addLog('   shouldUpdate: ${validation.shouldUpdate}');
      _addLog('   canScan: ${validation.canScan}');
      _addLog('   timeDifference: ${validation.timeDifference?.inMinutes} min');
      
      if (validation.shouldUpdate) {
        _addLog('⚠️ Redirecting to update time page');
        if (mounted) {
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
        }
      } else {
        _addLog('✅ Validation passed, can scan');
        _startCountdownTimer();
      }
    } catch (e) {
      _addLog('❌ Error validating: $e');
      _startCountdownTimer();
    }
  }

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      debugLog += '[$timestamp] $message\n';
    });
    print(message);
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ClockinDashboardPage(contractId: widget.contractId),
      ),
    );
  }

  Future<void> _simulateScan(String btnId, String workerName) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    _addLog('🔄 Simulating scan for $workerName (BTN: $btnId)');

    try {
      // Obtener estado actual de BD local
      await _logDatabaseState('BEFORE SCAN');

      _addLog('📞 Calling scanWorker API...');
      
      // Simular escaneo usando el provider (esto llama al API y registra en BD local)
      await ref.read(clockinProvider.notifier).scanWorker(btnId);

      _addLog('✅ Worker scanned and registered in local DB');

      // Ver estado después del escaneo
      await _logDatabaseState('AFTER SCAN');

      _addLog('✅ SCAN COMPLETE - Worker registered with current time');
      _addLog('💡 Now wait 1+ minute and press Debug button again to test validation');

      setState(() {
        isProcessing = false;
      });

      // Mostrar mensaje de éxito con instrucciones
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $workerName escaneado. Espera 1+ min y vuelve a entrar al debug'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Volver al dashboard después de 2 segundos
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _addLog('🔙 Returning to dashboard...');
        _navigateBackToDashboard();
      }
    } catch (e) {
      _addLog('❌ Error scanning: $e');
      _addLog('Stack trace: ${StackTrace.current}');
      
      setState(() {
        isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _logDatabaseState(String label) async {
    _addLog('\n📊 === DATABASE STATE $label ===');
    
    try {
      // Estado de workday_on
      final workdayOn = await DatabaseHelper.getWorkdayOn();
      if (workdayOn != null) {
        _addLog('📋 workday_on:');
        _addLog('   workday_id: ${workdayOn['workday_id']}');
        _addLog('   current_session_in: ${workdayOn['current_session_in']}');
        _addLog('   ult_clock: ${workdayOn['ult_clock']}');
        _addLog('   sultclock: ${workdayOn['sultclock']}');
      } else {
        _addLog('⚠️ No workday_on found');
      }

      // Sesión actual
      final currentSession = await DatabaseHelper.getCurrentSession('IN');
      if (currentSession != null) {
        _addLog('📋 current_session (IN):');
        _addLog('   id: ${currentSession['id']}');
        _addLog('   supervisor_id: ${currentSession['supervisor_id']}');
        _addLog('   session_start_time: ${currentSession['session_start_time']}');
        
        // Workers en esta sesión
        final sessionId = currentSession['id'] as int;
        final workers = await DatabaseHelper.getScannedWorkersBySession(sessionId);
        _addLog('   workers_count: ${workers.length}');
        for (var worker in workers) {
          _addLog('     - ${worker['worker_name']} (${worker['worker_btn_id']}) at ${worker['clock_time']}');
        }
      } else {
        _addLog('⚠️ No current session found');
      }
    } catch (e) {
      _addLog('❌ Error logging DB state: $e');
    }
    
    _addLog('=== END DATABASE STATE ===\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clock-In Scanner (DEBUG MODE)'),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateBackToDashboard,
        ),
      ),
      body: Column(
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Tiempo restante: ${remainingSeconds}s',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Botones de debug
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'FLUJO DE PRUEBA',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Escanea Worker 1\n'
                        '2. Vuelve al dashboard (automático)\n'
                        '3. Espera 1+ minuto\n'
                        '4. Presiona 🐛 de nuevo\n'
                        '5. Debe pedir actualizar hora',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SIMULAR ESCANEOS',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...debugWorkers.map((worker) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton.icon(
                    onPressed: isProcessing 
                        ? null 
                        : () => _simulateScan(worker['btnId']!, worker['name']!),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text('Escanear ${worker['name']} (${worker['btnId']})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                )),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _logDatabaseState('MANUAL CHECK');
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Ver Estado BD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Log area
          Expanded(
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  debugLog.isEmpty ? 'Esperando acciones...' : debugLog,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
