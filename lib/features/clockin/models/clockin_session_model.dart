import 'package:equatable/equatable.dart';
import 'workday_model.dart';
import 'worker_scan_model.dart';

enum ClockinStatus { notStarted, setup, active, finished }

class ClockinSessionModel extends Equatable {
  final int? sessionId;
  final WorkdayModel? workday;
  final List<WorkerScanModel> workers;
  final List<WorkerScanModel> scannedWorkers;
  final List<WorkerScanModel> absentWorkers;
  final ClockinStatus status;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int? supervisorId;
  final String? contractId;
  final Map<String, dynamic>? sessionConfig;
  final String? currentLocation;
  final bool isAutomaticMode;
  final bool supervisorHasClockin;

  const ClockinSessionModel({
    this.sessionId,
    this.workday,
    this.workers = const [],
    this.scannedWorkers = const [],
    this.absentWorkers = const [],
    this.status = ClockinStatus.notStarted,
    this.startedAt,
    this.finishedAt,
    this.supervisorId,
    this.contractId,
    this.sessionConfig,
    this.currentLocation,
    this.isAutomaticMode = false,
    this.supervisorHasClockin = false,
  });

  factory ClockinSessionModel.fromJson(Map<String, dynamic> json) {
    return ClockinSessionModel(
      sessionId: json['session_id'] as int?,
      workday: json['workday'] != null 
          ? WorkdayModel.fromJson(json['workday'] as Map<String, dynamic>)
          : null,
      workers: (json['workers'] as List<dynamic>?)
          ?.map((w) => WorkerScanModel.fromJson(w as Map<String, dynamic>))
          .toList() ?? [],
      scannedWorkers: (json['scanned_workers'] as List<dynamic>?)
          ?.map((w) => WorkerScanModel.fromJson(w as Map<String, dynamic>))
          .toList() ?? [],
      absentWorkers: (json['absent_workers'] as List<dynamic>?)
          ?.map((w) => WorkerScanModel.fromJson(w as Map<String, dynamic>))
          .toList() ?? [],
      status: _getStatusFromString(json['status'] as String?),
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at'] as String)
          : null,
      finishedAt: json['finished_at'] != null 
          ? DateTime.parse(json['finished_at'] as String)
          : null,
      supervisorId: json['supervisor_id'] as int?,
      contractId: json['contract_id'] as String?,
      sessionConfig: json['session_config'] as Map<String, dynamic>?,
      currentLocation: json['current_location'] as String?,
      isAutomaticMode: json['is_automatic_mode'] as bool? ?? false,
    );
  }

  static ClockinStatus _getStatusFromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'setup':
        return ClockinStatus.setup;
      case 'active':
        return ClockinStatus.active;
      case 'finished':
        return ClockinStatus.finished;
      default:
        return ClockinStatus.notStarted;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'workday': workday?.toJson(),
      'workers': workers.map((w) => w.toJson()).toList(),
      'scanned_workers': scannedWorkers.map((w) => w.toJson()).toList(),
      'absent_workers': absentWorkers.map((w) => w.toJson()).toList(),
      'status': status.name,
      'started_at': startedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'supervisor_id': supervisorId,
      'contract_id': contractId,
      'session_config': sessionConfig,
      'current_location': currentLocation,
      'is_automatic_mode': isAutomaticMode,
      'supervisor_has_clockin': supervisorHasClockin,
    };
  }

  ClockinSessionModel copyWith({
    int? sessionId,
    WorkdayModel? workday,
    List<WorkerScanModel>? workers,
    List<WorkerScanModel>? scannedWorkers,
    List<WorkerScanModel>? absentWorkers,
    ClockinStatus? status,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? supervisorId,
    String? contractId,
    Map<String, dynamic>? sessionConfig,
    String? currentLocation,
    bool? isAutomaticMode,
    bool? supervisorHasClockin,
  }) {
    return ClockinSessionModel(
      sessionId: sessionId ?? this.sessionId,
      workday: workday ?? this.workday,
      workers: workers ?? this.workers,
      scannedWorkers: scannedWorkers ?? this.scannedWorkers,
      absentWorkers: absentWorkers ?? this.absentWorkers,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      supervisorId: supervisorId ?? this.supervisorId,
      contractId: contractId ?? this.contractId,
      sessionConfig: sessionConfig ?? this.sessionConfig,
      currentLocation: currentLocation ?? this.currentLocation,
      isAutomaticMode: isAutomaticMode ?? this.isAutomaticMode,
      supervisorHasClockin: supervisorHasClockin ?? this.supervisorHasClockin,
    );
  }

  // Getters útiles
  bool get isNotStarted => status == ClockinStatus.notStarted;
  bool get isInSetup => status == ClockinStatus.setup;
  bool get isActive => status == ClockinStatus.active;
  bool get isFinished => status == ClockinStatus.finished;

  int get totalWorkers => workers.length;
  int get scannedCount => scannedWorkers.length;
  int get absentCount => absentWorkers.length;
  int get pendingCount => totalWorkers - scannedCount - absentCount;

  double get completionPercentage {
    if (totalWorkers == 0) return 0.0;
    return (scannedCount + absentCount) / totalWorkers;
  }

  List<WorkerScanModel> get pendingWorkers {
    final processedIds = [
      ...scannedWorkers.map((w) => w.id),
      ...absentWorkers.map((w) => w.id),
    ].toSet();
    
    return workers.where((w) => !processedIds.contains(w.id)).toList();
  }

  bool get canStartScanning => isActive && workday?.canStartClocking == true;
  bool get canFinishSession => isActive && pendingCount == 0;

  String get statusDisplayName {
    switch (status) {
      case ClockinStatus.notStarted:
        return 'Not Started';
      case ClockinStatus.setup:
        return 'Setup Required';
      case ClockinStatus.active:
        return 'Active';
      case ClockinStatus.finished:
        return 'Finished';
    }
  }

  // Métodos para actualizar la sesión
  ClockinSessionModel addScannedWorker(WorkerScanModel worker) {
    final updatedScanned = [...scannedWorkers, worker];
    final updatedAbsent = absentWorkers.where((w) => w.id != worker.id).toList();
    
    return copyWith(
      scannedWorkers: updatedScanned,
      absentWorkers: updatedAbsent,
    );
  }

  ClockinSessionModel addAbsentWorker(WorkerScanModel worker) {
    final updatedAbsent = [...absentWorkers, worker];
    final updatedScanned = scannedWorkers.where((w) => w.id != worker.id).toList();
    
    return copyWith(
      absentWorkers: updatedAbsent,
      scannedWorkers: updatedScanned,
    );
  }

  ClockinSessionModel removeWorkerFromProcessed(int workerId) {
    final updatedScanned = scannedWorkers.where((w) => w.id != workerId).toList();
    final updatedAbsent = absentWorkers.where((w) => w.id != workerId).toList();
    
    return copyWith(
      scannedWorkers: updatedScanned,
      absentWorkers: updatedAbsent,
    );
  }

  ClockinSessionModel updateWorkday(WorkdayModel newWorkday) {
    return copyWith(workday: newWorkday);
  }

  ClockinSessionModel startSession({
    required int supervisorId,
    required String location,
  }) {
    return copyWith(
      status: ClockinStatus.active,
      startedAt: DateTime.now(),
      supervisorId: supervisorId,
      currentLocation: location,
    );
  }

  ClockinSessionModel finishSession() {
    return copyWith(
      status: ClockinStatus.finished,
      finishedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        workday,
        workers,
        scannedWorkers,
        absentWorkers,
        status,
        startedAt,
        finishedAt,
        supervisorId,
        contractId,
        sessionConfig,
        currentLocation,
        isAutomaticMode,
        supervisorHasClockin,
      ];
}
