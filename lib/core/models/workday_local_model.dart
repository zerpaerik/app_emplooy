class WorkdayLocalModel {
  final int id;
  final int? workdayId;
  final DateTime? clockInInit;
  final DateTime? clockInFin;
  final DateTime? clockOutInit;
  final DateTime? clockOutFin;
  final String? clockInLocation;
  final String? clockOutLocation;
  final bool hasClockIn;
  final bool hasClockOut;
  final DateTime? defaultInit;
  final DateTime? defaultExit;
  final DateTime? ultClock;
  final DateTime? ultClockOut;
  final String? supervisorClockIn;
  final String? supervisorClockOut;
  final int? currentSessionIn;
  final int? currentSessionOut;

  WorkdayLocalModel({
    required this.id,
    this.workdayId,
    this.clockInInit,
    this.clockInFin,
    this.clockOutInit,
    this.clockOutFin,
    this.clockInLocation,
    this.clockOutLocation,
    required this.hasClockIn,
    required this.hasClockOut,
    this.defaultInit,
    this.defaultExit,
    this.ultClock,
    this.ultClockOut,
    this.supervisorClockIn,
    this.supervisorClockOut,
    this.currentSessionIn,
    this.currentSessionOut,
  });

  factory WorkdayLocalModel.fromMap(Map<String, dynamic> map) {
    return WorkdayLocalModel(
      id: map['id'] as int,
      workdayId: map['workday_id'] as int?,
      clockInInit: map['clock_in_init'] != null
          ? DateTime.parse(map['clock_in_init'] as String)
          : null,
      clockInFin: map['clock_in_fin'] != null
          ? DateTime.parse(map['clock_in_fin'] as String)
          : null,
      clockOutInit: map['clock_out_init'] != null
          ? DateTime.parse(map['clock_out_init'] as String)
          : null,
      clockOutFin: map['clock_out_fin'] != null
          ? DateTime.parse(map['clock_out_fin'] as String)
          : null,
      clockInLocation: map['clock_in_location'] as String?,
      clockOutLocation: map['clock_out_location'] as String?,
      hasClockIn: (map['has_clockin'] as int) == 1,
      hasClockOut: (map['has_clockout'] as int) == 1,
      defaultInit: map['default_init'] != null && (map['default_init'] as String).isNotEmpty
          ? DateTime.parse(map['default_init'] as String)
          : null,
      defaultExit: map['default_exit'] != null && (map['default_exit'] as String).isNotEmpty
          ? DateTime.parse(map['default_exit'] as String)
          : null,
      ultClock: map['ult_clock'] != null && (map['ult_clock'] as String).isNotEmpty
          ? DateTime.parse(map['ult_clock'] as String)
          : null,
      ultClockOut: map['ultclokout'] != null && (map['ultclokout'] as String).isNotEmpty
          ? DateTime.parse(map['ultclokout'] as String)
          : null,
      supervisorClockIn: map['sultclock'] as String?,
      supervisorClockOut: map['sultclokout'] as String?,
      currentSessionIn: map['current_session_in'] as int?,
      currentSessionOut: map['current_session_out'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workday_id': workdayId,
      'clock_in_init': clockInInit?.toIso8601String(),
      'clock_in_fin': clockInFin?.toIso8601String(),
      'clock_out_init': clockOutInit?.toIso8601String(),
      'clock_out_fin': clockOutFin?.toIso8601String(),
      'clock_in_location': clockInLocation,
      'clock_out_location': clockOutLocation,
      'has_clockin': hasClockIn ? 1 : 0,
      'has_clockout': hasClockOut ? 1 : 0,
      'default_init': defaultInit?.toIso8601String(),
      'default_exit': defaultExit?.toIso8601String(),
      'ult_clock': ultClock?.toIso8601String() ?? '',
      'ultclokout': ultClockOut?.toIso8601String() ?? '',
      'sultclock': supervisorClockIn ?? '',
      'sultclokout': supervisorClockOut ?? '',
      'current_session_in': currentSessionIn,
      'current_session_out': currentSessionOut,
    };
  }
}

class ClockSessionModel {
  final int id;
  final int workdayId;
  final String supervisorId;
  final String? supervisorName;
  final DateTime sessionStartTime;
  final String clockType;
  final int workersCount;
  final bool isAutoMode;
  final DateTime createdAt;

  ClockSessionModel({
    required this.id,
    required this.workdayId,
    required this.supervisorId,
    this.supervisorName,
    required this.sessionStartTime,
    required this.clockType,
    required this.workersCount,
    required this.isAutoMode,
    required this.createdAt,
  });

  factory ClockSessionModel.fromMap(Map<String, dynamic> map) {
    return ClockSessionModel(
      id: map['id'] as int,
      workdayId: map['workday_id'] as int,
      supervisorId: map['supervisor_id'] as String,
      supervisorName: map['supervisor_name'] as String?,
      sessionStartTime: DateTime.parse(map['session_start_time'] as String),
      clockType: map['clock_type'] as String,
      workersCount: map['workers_count'] as int,
      isAutoMode: (map['is_auto_mode'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workday_id': workdayId,
      'supervisor_id': supervisorId,
      'supervisor_name': supervisorName,
      'session_start_time': sessionStartTime.toIso8601String(),
      'clock_type': clockType,
      'workers_count': workersCount,
      'is_auto_mode': isAutoMode ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ScannedWorkerModel {
  final int id;
  final int sessionId;
  final int workerId;
  final String workerBtnId;
  final String? workerName;
  final DateTime clockTime;
  final String clockType;
  final String? location;
  final DateTime scannedAt;

  ScannedWorkerModel({
    required this.id,
    required this.sessionId,
    required this.workerId,
    required this.workerBtnId,
    this.workerName,
    required this.clockTime,
    required this.clockType,
    this.location,
    required this.scannedAt,
  });

  factory ScannedWorkerModel.fromMap(Map<String, dynamic> map) {
    return ScannedWorkerModel(
      id: map['id'] as int,
      sessionId: map['session_id'] as int,
      workerId: map['worker_id'] as int,
      workerBtnId: map['worker_btn_id'] as String,
      workerName: map['worker_name'] as String?,
      clockTime: DateTime.parse(map['clock_time'] as String),
      clockType: map['clock_type'] as String,
      location: map['location'] as String?,
      scannedAt: DateTime.parse(map['scanned_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'worker_id': workerId,
      'worker_btn_id': workerBtnId,
      'worker_name': workerName,
      'clock_time': clockTime.toIso8601String(),
      'clock_type': clockType,
      'location': location,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }
}
