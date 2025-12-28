import 'package:equatable/equatable.dart';

enum WorkerStatus { pending, scanned, absent, excluded }

enum AbsenceReason {
  workPermit(6, 'Ausente con permiso de trabajo'),
  illness(2, 'Ausente por enfermedad'),
  accident(3, 'Ausente por accidente'),
  abandonment(4, 'Abandono del trabajo'),
  unjustified(5, 'Ausente sin justificación'),
  other(1, 'Otro motivo');

  const AbsenceReason(this.code, this.description);
  final int code;
  final String description;

  static AbsenceReason fromCode(int code) {
    return AbsenceReason.values.firstWhere(
      (reason) => reason.code == code,
      orElse: () => AbsenceReason.other,
    );
  }

  static AbsenceReason fromDescription(String description) {
    return AbsenceReason.values.firstWhere(
      (reason) => reason.description == description,
      orElse: () => AbsenceReason.other,
    );
  }
}

class WorkerScanModel extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? btnId;
  final String? profileImage;
  final WorkerStatus status;
  final DateTime? scannedAt;
  final String? scannedLocation;
  final AbsenceReason? absenceReason;
  final String? absenceExcuse;
  final int? scannedByUserId;
  final String? category;
  final Map<String, dynamic>? additionalData;

  const WorkerScanModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.btnId,
    this.profileImage,
    this.status = WorkerStatus.pending,
    this.scannedAt,
    this.scannedLocation,
    this.absenceReason,
    this.absenceExcuse,
    this.scannedByUserId,
    this.category,
    this.additionalData,
  });

  factory WorkerScanModel.fromJson(Map<String, dynamic> json) {
    return WorkerScanModel(
      id: json['id'] as int? ?? json['user_id'] as int? ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      btnId: json['btn_id'] as String?,
      profileImage: json['profile_image'] as String?,
      status: _getStatusFromJson(json),
      scannedAt: json['scanned_at'] != null 
          ? DateTime.parse(json['scanned_at'] as String)
          : null,
      scannedLocation: json['scanned_location'] as String?,
      absenceReason: json['worker_status'] != null 
          ? AbsenceReason.fromCode(json['worker_status'] as int)
          : null,
      absenceExcuse: json['absence_excuse'] as String?,
      scannedByUserId: json['scanned_by_user_id'] as int?,
      category: json['category'] as String?,
      additionalData: json['additional_data'] as Map<String, dynamic>?,
    );
  }

  static WorkerStatus _getStatusFromJson(Map<String, dynamic> json) {
    if (json['worker_status'] != null && json['worker_status'] != 1) {
      return WorkerStatus.absent;
    } else if (json['scanned_at'] != null || json['clock_in_time'] != null) {
      return WorkerStatus.scanned;
    } else {
      return WorkerStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'btn_id': btnId,
      'profile_image': profileImage,
      'status': status.name,
      'scanned_at': scannedAt?.toIso8601String(),
      'scanned_location': scannedLocation,
      'worker_status': absenceReason?.code,
      'absence_excuse': absenceExcuse,
      'scanned_by_user_id': scannedByUserId,
      'category': category,
      'additional_data': additionalData,
    };
  }

  WorkerScanModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? btnId,
    String? profileImage,
    WorkerStatus? status,
    DateTime? scannedAt,
    String? scannedLocation,
    AbsenceReason? absenceReason,
    String? absenceExcuse,
    int? scannedByUserId,
    String? category,
    Map<String, dynamic>? additionalData,
  }) {
    return WorkerScanModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      btnId: btnId ?? this.btnId,
      profileImage: profileImage ?? this.profileImage,
      status: status ?? this.status,
      scannedAt: scannedAt ?? this.scannedAt,
      scannedLocation: scannedLocation ?? this.scannedLocation,
      absenceReason: absenceReason ?? this.absenceReason,
      absenceExcuse: absenceExcuse ?? this.absenceExcuse,
      scannedByUserId: scannedByUserId ?? this.scannedByUserId,
      category: category ?? this.category,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Getters útiles
  String get fullName => '$firstName $lastName';
  
  bool get isPending => status == WorkerStatus.pending;
  bool get isScanned => status == WorkerStatus.scanned;
  bool get isAbsent => status == WorkerStatus.absent;
  bool get isExcluded => status == WorkerStatus.excluded;
  
  String get displayId => btnId ?? id.toString();
  
  String get statusDisplayName {
    switch (status) {
      case WorkerStatus.pending:
        return 'Pending';
      case WorkerStatus.scanned:
        return 'Scanned';
      case WorkerStatus.absent:
        return 'Absent';
      case WorkerStatus.excluded:
        return 'Excluded';
    }
  }

  String? get absenceDisplayReason {
    return absenceReason?.description;
  }

  // Factory methods para crear workers con estados específicos
  factory WorkerScanModel.scanned({
    required WorkerScanModel worker,
    required DateTime scannedAt,
    required String scannedLocation,
    required int scannedByUserId,
  }) {
    return worker.copyWith(
      status: WorkerStatus.scanned,
      scannedAt: scannedAt,
      scannedLocation: scannedLocation,
      scannedByUserId: scannedByUserId,
    );
  }

  factory WorkerScanModel.absent({
    required WorkerScanModel worker,
    required AbsenceReason reason,
    String? excuse,
  }) {
    return worker.copyWith(
      status: WorkerStatus.absent,
      absenceReason: reason,
      absenceExcuse: excuse,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        btnId,
        profileImage,
        status,
        scannedAt,
        scannedLocation,
        absenceReason,
        absenceExcuse,
        scannedByUserId,
        category,
        additionalData,
      ];
}
