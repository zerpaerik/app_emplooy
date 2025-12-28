class CrewSheet {
  final int id;
  final String status;
  final String date;
  final String? entryTime;
  final String? exitTime;
  final int workersCount;
  final bool isCheckInFinished;
  final bool isCheckOutStarted;
  final bool isCheckOutFinished;

  const CrewSheet({
    required this.id,
    required this.status,
    required this.date,
    this.entryTime,
    this.exitTime,
    required this.workersCount,
    required this.isCheckInFinished,
    required this.isCheckOutStarted,
    required this.isCheckOutFinished,
  });

  factory CrewSheet.fromJson(Map<String, dynamic> json) {
    return CrewSheet(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      date: json['date'] ?? '',
      entryTime: json['entry_time'],
      exitTime: json['exit_time'],
      workersCount: json['workers_count'] ?? 0,
      isCheckInFinished: json['is_check_in_finished'] ?? false,
      isCheckOutStarted: json['is_check_out_started'] ?? false,
      isCheckOutFinished: json['is_check_out_finished'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'date': date,
      'entry_time': entryTime,
      'exit_time': exitTime,
      'workers_count': workersCount,
      'is_check_in_finished': isCheckInFinished,
      'is_check_out_started': isCheckOutStarted,
      'is_check_out_finished': isCheckOutFinished,
    };
  }

  bool get canStartCheckOut => isCheckInFinished && !isCheckOutStarted;
  bool get isInProgress => !isCheckInFinished || (isCheckOutStarted && !isCheckOutFinished);
  bool get isCompleted => isCheckInFinished && isCheckOutFinished;
}

class Worker {
  final int id;
  final String firstName;
  final String lastName;
  final String btnId;
  final String? profileImage;
  final String? status;

  const Worker({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.btnId,
    this.profileImage,
    this.status,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      btnId: json['btn_id'] ?? '',
      profileImage: json['profile_image'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'btn_id': btnId,
      'profile_image': profileImage,
      'status': status,
    };
  }

  String get fullName => '$firstName $lastName';
}
