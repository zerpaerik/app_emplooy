import 'package:equatable/equatable.dart';
import 'report_time_model.dart';

class WorkdayReportModel extends Equatable {
  final int? id;
  final int workdayId;
  final DateTime reportDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? comments;
  
  // Personal
  final List<int> workerIds;
  final List<int> driverIds;
  final List<int> absentWorkerIds;
  
  // Tiempos
  final ReportTimeModel? workdayTime;
  final ReportTimeModel? lunchTime;
  final ReportTimeModel? standbyTime;
  final ReportTimeModel? travelTime;
  
  // Recursos
  final List<int> vehicleIds;
  final String? equipment;
  final String? materials;
  
  final String status; // draft, submitted, approved
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? workedHours;

  const WorkdayReportModel({
    this.id,
    required this.workdayId,
    required this.reportDate,
    this.startTime,
    this.endTime,
    this.comments,
    this.workerIds = const [],
    this.driverIds = const [],
    this.absentWorkerIds = const [],
    this.workdayTime,
    this.lunchTime,
    this.standbyTime,
    this.travelTime,
    this.vehicleIds = const [],
    this.equipment,
    this.materials,
    this.status = 'draft',
    this.createdAt,
    this.updatedAt,
    this.workedHours,
  });

  bool get isDraft => status == 'draft';
  bool get isSubmitted => status == 'submitted';
  bool get isApproved => status == 'approved';
  bool get isFinalized => status == 'submitted' || status == 'approved';

  int get totalWorkers => workerIds.length;
  int get totalDrivers => driverIds.length;
  int get totalAbsent => absentWorkerIds.length;
  int get totalVehicles => vehicleIds.length;

  factory WorkdayReportModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parsear tiempos de workday
      ReportTimeModel? workdayTime;
      if (json['workday_entry_time'] != null && json['workday_departure_time'] != null) {
        workdayTime = ReportTimeModel(
          startTime: DateTime.parse(json['workday_entry_time'] as String),
          endTime: DateTime.parse(json['workday_departure_time'] as String),
        );
      }

      // Parsear tiempos de lunch
      ReportTimeModel? lunchTime;
      if (json['lunch_start_time'] != null && json['lunch_end_time'] != null) {
        lunchTime = ReportTimeModel(
          startTime: DateTime.parse(json['lunch_start_time'] as String),
          endTime: DateTime.parse(json['lunch_end_time'] as String),
        );
      }

      // Parsear tiempos de standby
      ReportTimeModel? standbyTime;
      if (json['standby_start_time'] != null && json['standby_end_time'] != null) {
        standbyTime = ReportTimeModel(
          startTime: DateTime.parse(json['standby_start_time'] as String),
          endTime: DateTime.parse(json['standby_end_time'] as String),
        );
      }

      // Parsear tiempos de travel
      ReportTimeModel? travelTime;
      if (json['travel_start_time'] != null && json['travel_end_time'] != null) {
        travelTime = ReportTimeModel(
          startTime: DateTime.parse(json['travel_start_time'] as String),
          endTime: DateTime.parse(json['travel_end_time'] as String),
        );
      }

      return WorkdayReportModel(
        id: json['id'] as int?,
        workdayId: json['workday'] as int? ?? 0,
        reportDate: json['workday_entry_time'] != null 
            ? DateTime.parse(json['workday_entry_time'] as String)
            : DateTime.now(),
        startTime: json['clock_in_start'] != null 
            ? DateTime.parse(json['clock_in_start'] as String)
            : null,
        endTime: json['clock_out_start'] != null 
            ? DateTime.parse(json['clock_out_start'] as String)
            : null,
        comments: json['comments'] as String?,
        workerIds: json['workers'] != null ? [json['workers'] as int] : [],
        driverIds: [],
        absentWorkerIds: [],
        workdayTime: workdayTime,
        lunchTime: lunchTime,
        standbyTime: standbyTime,
        travelTime: travelTime,
        vehicleIds: (json['vehicles_list'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ?? [],
        equipment: null,
        materials: null,
        status: json['status']?.toString() ?? '1',
        createdAt: json['created'] != null
            ? DateTime.parse(json['created'] as String)
            : null,
        updatedAt: null,
        workedHours: json['worked_hours'] != null 
            ? (json['worked_hours'] is num 
                ? (json['worked_hours'] as num).toDouble()
                : double.tryParse(json['worked_hours'].toString()))
            : null,
      );
    } catch (e) {
      print('Error parsing WorkdayReportModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workday_id': workdayId,
      'report_date': reportDate.toIso8601String(),
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'comments': comments,
      'worker_ids': workerIds,
      'driver_ids': driverIds,
      'absent_worker_ids': absentWorkerIds,
      'workday_time': workdayTime?.toJson(),
      'lunch_time': lunchTime?.toJson(),
      'standby_time': standbyTime?.toJson(),
      'travel_time': travelTime?.toJson(),
      'vehicle_ids': vehicleIds,
      'equipment': equipment,
      'materials': materials,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  WorkdayReportModel copyWith({
    int? id,
    int? workdayId,
    DateTime? reportDate,
    DateTime? startTime,
    DateTime? endTime,
    String? comments,
    List<int>? workerIds,
    List<int>? driverIds,
    List<int>? absentWorkerIds,
    ReportTimeModel? workdayTime,
    ReportTimeModel? lunchTime,
    ReportTimeModel? standbyTime,
    ReportTimeModel? travelTime,
    List<int>? vehicleIds,
    String? equipment,
    String? materials,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? workedHours,
  }) {
    return WorkdayReportModel(
      id: id ?? this.id,
      workdayId: workdayId ?? this.workdayId,
      reportDate: reportDate ?? this.reportDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      comments: comments ?? this.comments,
      workerIds: workerIds ?? this.workerIds,
      driverIds: driverIds ?? this.driverIds,
      absentWorkerIds: absentWorkerIds ?? this.absentWorkerIds,
      workdayTime: workdayTime ?? this.workdayTime,
      lunchTime: lunchTime ?? this.lunchTime,
      standbyTime: standbyTime ?? this.standbyTime,
      travelTime: travelTime ?? this.travelTime,
      vehicleIds: vehicleIds ?? this.vehicleIds,
      equipment: equipment ?? this.equipment,
      materials: materials ?? this.materials,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workedHours: workedHours ?? this.workedHours,
    );
  }

  @override
  List<Object?> get props => [
        id,
        workdayId,
        reportDate,
        startTime,
        endTime,
        comments,
        workerIds,
        driverIds,
        absentWorkerIds,
        workdayTime,
        lunchTime,
        standbyTime,
        travelTime,
        vehicleIds,
        equipment,
        materials,
        status,
        createdAt,
        updatedAt,
      ];
}
