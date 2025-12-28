import 'package:equatable/equatable.dart';
import '../../clockin/models/workday_model.dart';
import 'worker_clockout_model.dart';

enum ClockoutStatus {
  notStarted,
  setup,
  active,
  finished,
}

class ClockoutSessionModel extends Equatable {
  final String? contractId;
  final String? contractName;
  final String? companyName;
  final WorkdayModel? workday;
  final List<WorkerClockoutModel> clockedOutWorkers;
  final List<WorkerClockoutModel> pendingWorkers;
  final int totalWorkers;
  final bool supervisorHasClockedOut;
  final ClockoutStatus status;
  final DateTime? lastScanTime;
  final String? lastScanSupervisorId;

  const ClockoutSessionModel({
    this.contractId,
    this.contractName,
    this.companyName,
    this.workday,
    this.clockedOutWorkers = const [],
    this.pendingWorkers = const [],
    this.totalWorkers = 0,
    this.supervisorHasClockedOut = false,
    this.status = ClockoutStatus.notStarted,
    this.lastScanTime,
    this.lastScanSupervisorId,
  });

  ClockoutSessionModel copyWith({
    String? contractId,
    String? contractName,
    String? companyName,
    WorkdayModel? workday,
    List<WorkerClockoutModel>? clockedOutWorkers,
    List<WorkerClockoutModel>? pendingWorkers,
    int? totalWorkers,
    bool? supervisorHasClockedOut,
    ClockoutStatus? status,
    DateTime? lastScanTime,
    String? lastScanSupervisorId,
  }) {
    return ClockoutSessionModel(
      contractId: contractId ?? this.contractId,
      contractName: contractName ?? this.contractName,
      companyName: companyName ?? this.companyName,
      workday: workday ?? this.workday,
      clockedOutWorkers: clockedOutWorkers ?? this.clockedOutWorkers,
      pendingWorkers: pendingWorkers ?? this.pendingWorkers,
      totalWorkers: totalWorkers ?? this.totalWorkers,
      supervisorHasClockedOut: supervisorHasClockedOut ?? this.supervisorHasClockedOut,
      status: status ?? this.status,
      lastScanTime: lastScanTime ?? this.lastScanTime,
      lastScanSupervisorId: lastScanSupervisorId ?? this.lastScanSupervisorId,
    );
  }

  bool get canFinishSession => 
      status == ClockoutStatus.active && 
      workday?.clockOutStart != null;

  bool get isClockInFinished => workday?.clockInEnd != null;

  double get completionPercentage {
    if (totalWorkers == 0) return 0.0;
    return (clockedOutWorkers.length / totalWorkers) * 100;
  }

  String get statusDisplayName {
    switch (status) {
      case ClockoutStatus.notStarted:
        return 'Not Started';
      case ClockoutStatus.setup:
        return 'Setup Required';
      case ClockoutStatus.active:
        return 'Active';
      case ClockoutStatus.finished:
        return 'Finished';
    }
  }

  @override
  List<Object?> get props => [
        contractId,
        contractName,
        companyName,
        workday,
        clockedOutWorkers,
        pendingWorkers,
        totalWorkers,
        supervisorHasClockedOut,
        status,
        lastScanTime,
        lastScanSupervisorId,
      ];
}
