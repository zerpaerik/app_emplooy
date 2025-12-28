class WorkerReportModel {
  final int id;
  final int workerId;
  final String btnId;
  final String firstName;
  final String lastName;
  final String? profileImage;
  
  // Roles
  final bool isSupervisor;
  final bool isLead;
  final bool wasDriver;
  
  // Tiempos reales
  final DateTime clockIn;
  final DateTime clockOut;
  
  // Tiempos programados del workday
  final DateTime workdayEntryTime;
  final DateTime workdayDepartureTime;
  
  // Duraciones
  final String displayWorkedHours;
  final String lunchDuration;
  final String standbyDuration;
  final String travelTime;
  
  // Estado de edición
  final int? editorId;
  final String? editorName;
  final DateTime? editedAt;
  
  // Categoría
  final WorkerReportCategory category;

  WorkerReportModel({
    required this.id,
    required this.workerId,
    required this.btnId,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    required this.isSupervisor,
    required this.isLead,
    required this.wasDriver,
    required this.clockIn,
    required this.clockOut,
    required this.workdayEntryTime,
    required this.workdayDepartureTime,
    required this.displayWorkedHours,
    required this.lunchDuration,
    required this.standbyDuration,
    required this.travelTime,
    this.editorId,
    this.editorName,
    this.editedAt,
    required this.category,
  });

  factory WorkerReportModel.fromJson(Map<String, dynamic> json) {
    try {
      return WorkerReportModel(
        id: json['id'] as int? ?? 0,
        workerId: json['worker_id'] as int? ?? json['worker'] as int? ?? 0,
        btnId: json['btn_id']?.toString() ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        profileImage: json['profile_image'] as String?,
        isSupervisor: json['is_supervisor'] as bool? ?? false,
        isLead: json['is_lead'] as bool? ?? json['was_lead'] as bool? ?? false,
        wasDriver: json['was_driver'] as bool? ?? false,
        clockIn: json['clock_in'] != null 
            ? DateTime.parse(json['clock_in'] as String)
            : DateTime.now(),
        clockOut: json['clock_out'] != null
            ? DateTime.parse(json['clock_out'] as String)
            : DateTime.now(),
        workdayEntryTime: json['workday_entry_time'] != null
            ? DateTime.parse(json['workday_entry_time'] as String)
            : DateTime.now(),
        workdayDepartureTime: json['workday_departure_time'] != null
            ? DateTime.parse(json['workday_departure_time'] as String)
            : DateTime.now(),
        displayWorkedHours: json['display_worked_hours']?.toString() ?? '00:00',
        lunchDuration: json['lunch_duration']?.toString() ?? '00:00:00',
        standbyDuration: json['standby_duration']?.toString() ?? '00:00:00',
        travelTime: json['travel_time']?.toString() ?? json['travel_duration']?.toString() ?? '00:00:00',
        editorId: json['editor'] as int?,
        editorName: json['editor_name'] as String?,
        editedAt: json['edited_at'] != null 
            ? DateTime.parse(json['edited_at'] as String)
            : null,
        category: _determineCategory(json),
      );
    } catch (e) {
      print('Error parsing WorkerReportModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static WorkerReportCategory _determineCategory(Map<String, dynamic> json) {
    try {
      final hasEditor = json['editor'] != null;
      final standbyDuration = json['standby_duration']?.toString() ?? '00:00:00';
      final hasStandby = standbyDuration != '00:00:00';
      
      if (hasEditor) {
        return WorkerReportCategory.reviewed;
      } else if (hasStandby) {
        return WorkerReportCategory.standby;
      }
      
      // Determinar si llegó tarde comparando clock_in con workday_entry_time
      if (json['clock_in'] != null && json['workday_entry_time'] != null) {
        final clockIn = DateTime.parse(json['clock_in'] as String);
        final entryTime = DateTime.parse(json['workday_entry_time'] as String);
        
        if (clockIn.isAfter(entryTime)) {
          return WorkerReportCategory.late;
        }
      }
      
      return WorkerReportCategory.onTime;
    } catch (e) {
      print('Error determining category: $e');
      return WorkerReportCategory.onTime;
    }
  }

  String get fullName => '$firstName $lastName';

  String get roleIcon {
    if (isSupervisor) return '👨‍💼';
    if (isLead) return '👷‍♂️';
    if (wasDriver) return '🚗';
    return '👤';
  }

  String get roleName {
    if (isSupervisor) return 'Supervisor';
    if (isLead) return 'Lead';
    if (wasDriver) return 'Driver';
    return 'Worker';
  }

  bool get isLate {
    return clockIn.isAfter(workdayEntryTime);
  }

  Duration get lateDuration {
    if (!isLate) return Duration.zero;
    return clockIn.difference(workdayEntryTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'btn_id': btnId,
      'first_name': firstName,
      'last_name': lastName,
      'profile_image': profileImage,
      'is_supervisor': isSupervisor,
      'is_lead': isLead,
      'was_driver': wasDriver,
      'clock_in': clockIn.toIso8601String(),
      'clock_out': clockOut.toIso8601String(),
      'workday_entry_time': workdayEntryTime.toIso8601String(),
      'workday_departure_time': workdayDepartureTime.toIso8601String(),
      'display_worked_hours': displayWorkedHours,
      'lunch_duration': lunchDuration,
      'standby_duration': standbyDuration,
      'travel_time': travelTime,
      'editor': editorId,
      'editor_name': editorName,
      'edited_at': editedAt?.toIso8601String(),
    };
  }
}

enum WorkerReportCategory {
  onTime,
  late,
  reviewed,
  standby,
}
