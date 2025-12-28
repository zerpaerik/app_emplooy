import '../../../core/database/database_helper.dart';
import '../../../core/models/workday_local_model.dart';

class ClockOutValidationResult {
  final bool shouldUpdate;
  final bool canScan;
  final Duration? timeDifference;
  final String? lastSupervisorId;
  final String? lastSupervisorName;
  final DateTime? lastScanTime;
  final int? currentSessionId;

  ClockOutValidationResult({
    required this.shouldUpdate,
    required this.canScan,
    this.timeDifference,
    this.lastSupervisorId,
    this.lastSupervisorName,
    this.lastScanTime,
    this.currentSessionId,
  });
}

class ClockOutValidationService {
  static Future<ClockOutValidationResult> validateScanTiming({
    required String currentSupervisorId,
    required String currentSupervisorName,
  }) async {
    final workdayOnMap = await DatabaseHelper.getWorkdayOn();
    
    if (workdayOnMap == null) {
      return ClockOutValidationResult(
        shouldUpdate: false,
        canScan: true,
      );
    }

    final workdayOn = WorkdayLocalModel.fromMap(workdayOnMap);
    
    if (workdayOn.ultClockOut == null || workdayOn.supervisorClockOut == null) {
      return ClockOutValidationResult(
        shouldUpdate: false,
        canScan: true,
      );
    }

    // CORRECCIÓN: Validar SIEMPRE el tiempo contra ultClockOut (como Worker)
    // NO verificar si hay workers escaneados - Worker no hace esto

    // Validar tiempo SIEMPRE (como Worker)
    final now = DateTime.now();
    final timeDiff = now.difference(workdayOn.ultClockOut!);
    
    final hasPassedMinute = timeDiff > const Duration(minutes: 1);
    final isDifferentSupervisor = workdayOn.supervisorClockOut != currentSupervisorId;

    print('🔍 Clock-Out Validation:');
    print('   Current Supervisor: $currentSupervisorId ($currentSupervisorName)');
    print('   Last Supervisor: ${workdayOn.supervisorClockOut}');
    print('   Last Scan (ultClockOut): ${workdayOn.ultClockOut}');
    print('   Current Time: $now');
    print('   Time Diff: ${timeDiff.inMinutes} minutes ${timeDiff.inSeconds % 60} seconds');
    print('   Has Passed Minute: $hasPassedMinute');
    print('   Is Different Supervisor: $isDifferentSupervisor');

    // Lógica simple como Worker: Si pasó >1 min O supervisor diferente → UpdateTime
    if (hasPassedMinute || isDifferentSupervisor) {
      print('⚠️  Validation Result: SHOULD UPDATE TIME');
      return ClockOutValidationResult(
        shouldUpdate: true,
        canScan: false,
        timeDifference: timeDiff,
        lastSupervisorId: workdayOn.supervisorClockOut,
        lastScanTime: workdayOn.ultClockOut,
        currentSessionId: workdayOn.currentSessionOut,
      );
    }

    print('✅ Validation Result: CAN SCAN (using current session)');
    return ClockOutValidationResult(
      shouldUpdate: false,
      canScan: true,
      currentSessionId: workdayOn.currentSessionOut,
    );
  }

  static Future<int> getOrCreateSession({
    required int workdayId,
    required String supervisorId,
    required String supervisorName,
    required DateTime sessionStartTime,
    required bool isAutoMode,
    bool useCurrentTimeForUltClock = true,  // true = creación inicial, false = actualización de hora
  }) async {
    final currentSessionMap = await DatabaseHelper.getCurrentSession('OUT');
    
    if (currentSessionMap != null) {
      final currentSession = ClockSessionModel.fromMap(currentSessionMap);
      
      if (currentSession.supervisorId == supervisorId) {
        final timeDiff = DateTime.now().difference(currentSession.sessionStartTime);
        
        if (timeDiff <= const Duration(minutes: 1)) {
          print('📌 Using existing session: ${currentSession.id}');
          return currentSession.id;
        }
      }
    }

    print('🆕 Creating new clock-out session for supervisor: $supervisorId');
    final sessionId = await DatabaseHelper.createClockSession(
      workdayId: workdayId,
      supervisorId: supervisorId,
      supervisorName: supervisorName,
      sessionStartTime: sessionStartTime,
      clockType: 'OUT',
      isAutoMode: isAutoMode,
      useCurrentTimeForUltClock: useCurrentTimeForUltClock,
    );

    print('✅ Session created with ID: $sessionId');
    return sessionId;
  }

  static Future<void> recordWorkerScan({
    required int sessionId,
    required int workerId,
    required String workerBtnId,
    required String workerName,
    required DateTime clockTime,
    required String location,
    required String supervisorId,
  }) async {
    await DatabaseHelper.addScannedWorker(
      sessionId: sessionId,
      workerId: workerId,
      workerBtnId: workerBtnId,
      workerName: workerName,
      clockTime: clockTime,
      clockType: 'OUT',
      location: location,
    );

    // Actualizar ultClockOut después de cada escaneo para validación correcta
    await DatabaseHelper.updateUltClockOut(clockTime, supervisorId);

    print('✅ Worker $workerName clocked out at $clockTime');
    print('📌 Updated ultClockOut to $clockTime for supervisor $supervisorId');
  }

  static Future<List<ScannedWorkerModel>> getWorkersInCurrentSession() async {
    final currentSessionMap = await DatabaseHelper.getCurrentSession('OUT');
    
    if (currentSessionMap == null) return [];
    
    final sessionId = currentSessionMap['id'] as int;
    final workersMap = await DatabaseHelper.getScannedWorkersBySession(sessionId);
    
    return workersMap.map((map) => ScannedWorkerModel.fromMap(map)).toList();
  }

  static Future<Map<String, dynamic>> getSessionStats(int sessionId) async {
    final workersMap = await DatabaseHelper.getScannedWorkersBySession(sessionId);
    final sessionMap = await DatabaseHelper.getCurrentSession('OUT');
    
    if (sessionMap == null) {
      return {
        'workers_count': 0,
        'supervisor_name': 'Unknown',
        'session_start_time': DateTime.now(),
      };
    }

    final session = ClockSessionModel.fromMap(sessionMap);
    
    return {
      'workers_count': workersMap.length,
      'supervisor_name': session.supervisorName ?? 'Unknown',
      'session_start_time': session.sessionStartTime,
      'is_auto_mode': session.isAutoMode,
    };
  }
}
