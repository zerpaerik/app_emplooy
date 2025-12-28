class WorkerClockinModel {
  final int id;
  final int workerId;
  final String firstName;
  final String lastName;
  final String btnId;
  final String? profileImage;
  final String clockDatetime;
  final String? temperature;
  final String? geographicalCoordinates;
  final bool verified;
  final String clockType;
  final String? message;
  final int? workdayId;

  WorkerClockinModel({
    required this.id,
    required this.workerId,
    required this.firstName,
    required this.lastName,
    required this.btnId,
    this.profileImage,
    required this.clockDatetime,
    this.temperature,
    this.geographicalCoordinates,
    required this.verified,
    required this.clockType,
    this.message,
    this.workdayId,
  });

  factory WorkerClockinModel.fromJson(Map<String, dynamic> json) {
    return WorkerClockinModel(
      id: json['id'] ?? 0,
      workerId: json['worker'] ?? json['worker_id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      btnId: json['btn_id'] ?? '',
      profileImage: json['profile_image'] ?? json['image'],
      clockDatetime: json['clock_datetime'] ?? json['created_at'] ?? '',
      temperature: json['temperature']?.toString(),
      geographicalCoordinates: json['geographical_coordinates'],
      verified: json['verified'] ?? false,
      clockType: json['clock_type'] ?? 'IN',
      message: json['message'],
      workdayId: json['workday'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker': workerId,
      'first_name': firstName,
      'last_name': lastName,
      'btn_id': btnId,
      'profile_image': profileImage,
      'clock_datetime': clockDatetime,
      'temperature': temperature,
      'geographical_coordinates': geographicalCoordinates,
      'verified': verified,
      'clock_type': clockType,
      'message': message,
      'workday': workdayId,
    };
  }

  WorkerClockinModel copyWith({
    int? id,
    int? workerId,
    String? firstName,
    String? lastName,
    String? btnId,
    String? profileImage,
    String? clockDatetime,
    String? temperature,
    String? geographicalCoordinates,
    bool? verified,
    String? clockType,
    String? message,
    int? workdayId,
  }) {
    return WorkerClockinModel(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      btnId: btnId ?? this.btnId,
      profileImage: profileImage ?? this.profileImage,
      clockDatetime: clockDatetime ?? this.clockDatetime,
      temperature: temperature ?? this.temperature,
      geographicalCoordinates: geographicalCoordinates ?? this.geographicalCoordinates,
      verified: verified ?? this.verified,
      clockType: clockType ?? this.clockType,
      message: message ?? this.message,
      workdayId: workdayId ?? this.workdayId,
    );
  }

  String get fullName => '$firstName $lastName';
  
  DateTime? get clockTime {
    try {
      return DateTime.parse(clockDatetime);
    } catch (e) {
      return null;
    }
  }

  String get formattedClockTime {
    final time = clockTime;
    if (time == null) return 'N/A';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool get isClockIn => clockType.toUpperCase() == 'IN';
  bool get isClockOut => clockType.toUpperCase() == 'OUT';
}
