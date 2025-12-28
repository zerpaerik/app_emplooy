import 'package:equatable/equatable.dart';

class WorkerClockoutModel extends Equatable {
  final int workerId;
  final String btnId;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final DateTime? clockTime;
  final bool hasClockout;

  const WorkerClockoutModel({
    required this.workerId,
    required this.btnId,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.clockTime,
    required this.hasClockout,
  });

  String get fullName => '$firstName $lastName';

  factory WorkerClockoutModel.fromJson(Map<String, dynamic> json) {
    // Parsear clock_datetime
    DateTime? clockDateTime;
    final clockDatetimeStr = json['clock_datetime'] as String?;
    if (clockDatetimeStr != null && clockDatetimeStr.isNotEmpty) {
      try {
        clockDateTime = DateTime.parse(clockDatetimeStr);
      } catch (e) {
        print('Error parsing clock_datetime: $e');
      }
    }
    
    return WorkerClockoutModel(
      workerId: json['worker_id'] as int? ?? json['id'] as int? ?? 0,
      btnId: json['btn_id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      profileImage: json['profile_image'] as String?,
      clockTime: clockDateTime,
      hasClockout: clockDateTime != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'worker_id': workerId,
      'btn_id': btnId,
      'first_name': firstName,
      'last_name': lastName,
      'profile_image': profileImage,
      'clock_datetime': clockTime?.toIso8601String(),
      'has_clockout': hasClockout,
    };
  }

  WorkerClockoutModel copyWith({
    int? workerId,
    String? btnId,
    String? firstName,
    String? lastName,
    String? profileImage,
    DateTime? clockTime,
    bool? hasClockout,
  }) {
    return WorkerClockoutModel(
      workerId: workerId ?? this.workerId,
      btnId: btnId ?? this.btnId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
      clockTime: clockTime ?? this.clockTime,
      hasClockout: hasClockout ?? this.hasClockout,
    );
  }

  @override
  List<Object?> get props => [
        workerId,
        btnId,
        firstName,
        lastName,
        profileImage,
        clockTime,
        hasClockout,
      ];
}
