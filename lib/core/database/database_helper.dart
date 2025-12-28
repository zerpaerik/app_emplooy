import 'local_database.dart';

class DatabaseHelper {
  static Future<Map<String, dynamic>?> getWorkdayOn() async {
    final db = await LocalDatabase.instance.database;
    final result = await db.query(
      'workday_online',
      where: 'id = ?',
      whereArgs: [1],
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> updateWorkdayId(int workdayId) async {
    final db = await LocalDatabase.instance.database;
    await db.update(
      'workday_online',
      {'workday_id': workdayId},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  static Future<int> createClockSession({
    required int workdayId,
    required String supervisorId,
    required String supervisorName,
    required DateTime sessionStartTime,
    required String clockType,
    required bool isAutoMode,
    bool useCurrentTimeForUltClock = true,  // true = usar DateTime.now(), false = usar sessionStartTime
  }) async {
    final db = await LocalDatabase.instance.database;
    
    final sessionId = await db.insert('clock_sessions', {
      'workday_id': workdayId,
      'supervisor_id': supervisorId,
      'supervisor_name': supervisorName,
      'session_start_time': sessionStartTime.toIso8601String(),
      'clock_type': clockType,
      'workers_count': 0,
      'is_auto_mode': isAutoMode ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    // CRÍTICO: Diferenciar entre creación inicial y actualización de hora
    // - Creación inicial (useCurrentTimeForUltClock=true): usar DateTime.now()
    // - Actualización de hora (useCurrentTimeForUltClock=false): usar sessionStartTime
    final ultClockTime = useCurrentTimeForUltClock ? DateTime.now() : sessionStartTime;
    
    if (clockType == 'IN') {
      await db.update(
        'workday_online',
        {
          'current_session_in': sessionId,
          'ult_clock': ultClockTime.toIso8601String(),
          'sultclock': supervisorId,
        },
        where: 'id = ?',
        whereArgs: [1],
      );
      if (useCurrentTimeForUltClock) {
        print('✅ Initialized ult_clock with CURRENT time: $ultClockTime (creación inicial)');
      } else {
        print('✅ Updated ult_clock with SELECTED time: $ultClockTime (actualización de hora)');
      }
    } else {
      await db.update(
        'workday_online',
        {
          'current_session_out': sessionId,
          'ultclokout': ultClockTime.toIso8601String(),
          'sultclokout': supervisorId,
        },
        where: 'id = ?',
        whereArgs: [1],
      );
      if (useCurrentTimeForUltClock) {
        print('✅ Initialized ultclokout with CURRENT time: $ultClockTime (creación inicial)');
      } else {
        print('✅ Updated ultclokout with SELECTED time: $ultClockTime (actualización de hora)');
      }
    }

    return sessionId;
  }

  static Future<Map<String, dynamic>?> getCurrentSession(String clockType) async {
    final db = await LocalDatabase.instance.database;
    final workdayOn = await getWorkdayOn();
    
    if (workdayOn == null) return null;
    
    final sessionId = clockType == 'IN' 
        ? workdayOn['current_session_in'] 
        : workdayOn['current_session_out'];
    
    if (sessionId == null) return null;
    
    final result = await db.query(
      'clock_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> addScannedWorker({
    required int sessionId,
    required int workerId,
    required String workerBtnId,
    required String workerName,
    required DateTime clockTime,
    required String clockType,
    required String location,
  }) async {
    final db = await LocalDatabase.instance.database;
    
    await db.insert('scanned_workers', {
      'session_id': sessionId,
      'worker_id': workerId,
      'worker_btn_id': workerBtnId,
      'worker_name': workerName,
      'clock_time': clockTime.toIso8601String(),
      'clock_type': clockType,
      'location': location,
      'scanned_at': DateTime.now().toIso8601String(),
    });

    await db.rawUpdate(
      'UPDATE clock_sessions SET workers_count = workers_count + 1 WHERE id = ?',
      [sessionId],
    );
  }

  static Future<List<Map<String, dynamic>>> getScannedWorkersBySession(int sessionId) async {
    final db = await LocalDatabase.instance.database;
    return await db.query(
      'scanned_workers',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'scanned_at ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> getAllSessionsForWorkday(
    int workdayId,
    String clockType,
  ) async {
    final db = await LocalDatabase.instance.database;
    return await db.query(
      'clock_sessions',
      where: 'workday_id = ? AND clock_type = ?',
      whereArgs: [workdayId, clockType],
      orderBy: 'created_at ASC',
    );
  }

  static Future<void> updateUltClock(DateTime clock, String supervisorId) async {
    final db = await LocalDatabase.instance.database;
    await db.update(
      'workday_online',
      {
        'ult_clock': clock.toIso8601String(),
        'sultclock': supervisorId,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  static Future<void> updateUltClockOut(DateTime clock, String supervisorId) async {
    final db = await LocalDatabase.instance.database;
    await db.update(
      'workday_online',
      {
        'ultclokout': clock.toIso8601String(),
        'sultclokout': supervisorId,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  static Future<void> updateDefaultInit(DateTime defaultInit) async {
    final db = await LocalDatabase.instance.database;
    await db.update(
      'workday_online',
      {'default_init': defaultInit.toIso8601String()},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  static Future<void> updateDefaultExit(DateTime defaultExit) async {
    final db = await LocalDatabase.instance.database;
    await db.update(
      'workday_online',
      {'default_exit': defaultExit.toIso8601String()},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  static Future<void> clearWorkdayData() async {
    final db = await LocalDatabase.instance.database;
    
    await db.delete('scanned_workers');
    await db.delete('clock_sessions');
    
    await db.update(
      'workday_online',
      {
        'workday_id': null,
        'clock_in_init': null,
        'clock_in_fin': null,
        'clock_out_init': null,
        'clock_out_fin': null,
        'clock_in_location': null,
        'clock_out_location': null,
        'has_clockin': 0,
        'has_clockout': 0,
        'default_init': null,
        'default_exit': null,
        'ult_clock': '',
        'ultclokout': '',
        'sultclock': '',
        'sultclokout': '',
        'current_session_in': null,
        'current_session_out': null,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
    
    print('✅ Workday data cleared successfully');
  }

  static Future<Map<String, dynamic>> getWorkdayStats(int workdayId) async {
    final db = await LocalDatabase.instance.database;
    
    final clockInSessions = await db.query(
      'clock_sessions',
      where: 'workday_id = ? AND clock_type = ?',
      whereArgs: [workdayId, 'IN'],
    );
    
    final clockOutSessions = await db.query(
      'clock_sessions',
      where: 'workday_id = ? AND clock_type = ?',
      whereArgs: [workdayId, 'OUT'],
    );
    
    final totalClockInWorkers = await db.rawQuery(
      'SELECT COUNT(DISTINCT worker_id) as count FROM scanned_workers WHERE session_id IN (SELECT id FROM clock_sessions WHERE workday_id = ? AND clock_type = ?)',
      [workdayId, 'IN'],
    );
    
    final totalClockOutWorkers = await db.rawQuery(
      'SELECT COUNT(DISTINCT worker_id) as count FROM scanned_workers WHERE session_id IN (SELECT id FROM clock_sessions WHERE workday_id = ? AND clock_type = ?)',
      [workdayId, 'OUT'],
    );
    
    return {
      'clock_in_sessions': clockInSessions.length,
      'clock_out_sessions': clockOutSessions.length,
      'total_clock_in_workers': totalClockInWorkers.first['count'] ?? 0,
      'total_clock_out_workers': totalClockOutWorkers.first['count'] ?? 0,
    };
  }

  static Future<bool> hasWorkerClockIn(int workdayId, int workerId) async {
    final db = await LocalDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scanned_workers WHERE worker_id = ? AND clock_type = ? AND session_id IN (SELECT id FROM clock_sessions WHERE workday_id = ?)',
      [workerId, 'IN', workdayId],
    );
    return (result.first['count'] as int) > 0;
  }

  static Future<bool> hasWorkerClockOut(int workdayId, int workerId) async {
    final db = await LocalDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scanned_workers WHERE worker_id = ? AND clock_type = ? AND session_id IN (SELECT id FROM clock_sessions WHERE workday_id = ?)',
      [workerId, 'OUT', workdayId],
    );
    return (result.first['count'] as int) > 0;
  }
}
