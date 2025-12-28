import 'package:equatable/equatable.dart';

enum WorkdayStatus { notStarted, setup, active, finished }

class WorkdayModel extends Equatable {
  final int? id;
  final int contractId;
  final String? clockInInit;
  final String? clockInEnd;
  final String? clockOutStart;
  final String? clockOutEnd;
  final String? defaultEntryTime;
  final String? defaultExitTime;
  final String? geographicalCoordinates;
  final bool supervisorClock;
  final String? temperature;
  final int? clockInFinisher;
  final int? clockOutFinisher;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final WorkdayStatus status;

  const WorkdayModel({
    this.id,
    required this.contractId,
    this.clockInInit,
    this.clockInEnd,
    this.clockOutStart,
    this.clockOutEnd,
    this.defaultEntryTime,
    this.defaultExitTime,
    this.geographicalCoordinates,
    this.supervisorClock = false,
    this.temperature,
    this.clockInFinisher,
    this.clockOutFinisher,
    this.createdAt,
    this.updatedAt,
    this.status = WorkdayStatus.notStarted,
  });

  factory WorkdayModel.fromJson(Map<String, dynamic> json) {
    return WorkdayModel(
      id: json['id'] as int?,
      contractId: json['contract_id'] as int? ?? json['contract'] as int? ?? 0,
      clockInInit: json['clock_in_init'] as String?,
      clockInEnd: json['clock_in_end'] as String?,
      clockOutStart: json['clock_out_start'] as String?,
      clockOutEnd: json['clock_out_end'] as String?,
      defaultEntryTime: json['default_entry_time'] as String?,
      defaultExitTime: json['default_exit_time'] as String?,
      geographicalCoordinates: json['geographical_coordinates'] as String?,
      supervisorClock: json['supervisor_clock'] as bool? ?? false,
      temperature: json['temperature'] as String?,
      clockInFinisher: json['clock_in_finisher'] as int?,
      clockOutFinisher: json['clock_out_finisher'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      status: _getStatusFromJson(json),
    );
  }

  static WorkdayStatus _getStatusFromJson(Map<String, dynamic> json) {
    if (json['clock_in_end'] != null) {
      return WorkdayStatus.finished;
    } else if (json['clock_in_init'] != null) {
      return WorkdayStatus.active;
    } else if (json['default_entry_time'] != null) {
      return WorkdayStatus.setup;
    } else {
      return WorkdayStatus.notStarted;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_id': contractId,
      'clock_in_init': clockInInit,
      'clock_in_end': clockInEnd,
      'clock_out_start': clockOutStart,
      'clock_out_end': clockOutEnd,
      'default_entry_time': defaultEntryTime,
      'default_exit_time': defaultExitTime,
      'geographical_coordinates': geographicalCoordinates,
      'supervisor_clock': supervisorClock,
      'temperature': temperature,
      'clock_in_finisher': clockInFinisher,
      'clock_out_finisher': clockOutFinisher,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  WorkdayModel copyWith({
    int? id,
    int? contractId,
    String? clockInInit,
    String? clockInEnd,
    String? clockOutStart,
    String? clockOutEnd,
    String? defaultEntryTime,
    String? defaultExitTime,
    String? geographicalCoordinates,
    bool? supervisorClock,
    String? temperature,
    int? clockInFinisher,
    int? clockOutFinisher,
    DateTime? createdAt,
    DateTime? updatedAt,
    WorkdayStatus? status,
  }) {
    return WorkdayModel(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      clockInInit: clockInInit ?? this.clockInInit,
      clockInEnd: clockInEnd ?? this.clockInEnd,
      clockOutStart: clockOutStart ?? this.clockOutStart,
      clockOutEnd: clockOutEnd ?? this.clockOutEnd,
      defaultEntryTime: defaultEntryTime ?? this.defaultEntryTime,
      defaultExitTime: defaultExitTime ?? this.defaultExitTime,
      geographicalCoordinates: geographicalCoordinates ?? this.geographicalCoordinates,
      supervisorClock: supervisorClock ?? this.supervisorClock,
      temperature: temperature ?? this.temperature,
      clockInFinisher: clockInFinisher ?? this.clockInFinisher,
      clockOutFinisher: clockOutFinisher ?? this.clockOutFinisher,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  // Getters útiles
  bool get isNotStarted => status == WorkdayStatus.notStarted;
  bool get isInSetup => status == WorkdayStatus.setup;
  bool get isActive => status == WorkdayStatus.active;
  bool get isFinished => status == WorkdayStatus.finished;
  
  bool get canStartClocking => isInSetup || (isActive && clockInInit == null);
  bool get canFinishClocking => isActive && clockInInit != null;
  
  String get statusDisplayName {
    switch (status) {
      case WorkdayStatus.notStarted:
        return 'Not Started';
      case WorkdayStatus.setup:
        return 'Setup Required';
      case WorkdayStatus.active:
        return 'Active';
      case WorkdayStatus.finished:
        return 'Finished';
    }
  }

  @override
  List<Object?> get props => [
        id,
        contractId,
        clockInInit,
        clockInEnd,
        clockOutStart,
        clockOutEnd,
        defaultEntryTime,
        defaultExitTime,
        geographicalCoordinates,
        supervisorClock,
        temperature,
        clockInFinisher,
        clockOutFinisher,
        createdAt,
        updatedAt,
        status,
      ];
}
