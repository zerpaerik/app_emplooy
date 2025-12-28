import 'package:equatable/equatable.dart';

class WorkerModel extends Equatable {
  final int id;
  final String btnId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? profileImage;
  final String? position;
  final String? department;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  const WorkerModel({
    required this.id,
    required this.btnId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.profileImage,
    this.position,
    this.department,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    // Log completo de los datos para ver todos los campos disponibles
    print('=== WORKER DATA ===');
    print('Full JSON: $json');
    print('Available keys: ${json.keys.toList()}');
    print('==================');

    return WorkerModel(
      id: json['id'] as int? ?? json['worker_id'] as int? ?? 0,
      btnId: json['btn_id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      profileImage: json['profile_image'] as String? ?? json['image'] as String?,
      position: json['position'] as String? ?? json['job_title'] as String?,
      department: json['department'] as String?,
      isActive: json['is_active'] as bool? ?? json['active'] as bool?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'btn_id': btnId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'position': position,
      'department': department,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  WorkerModel copyWith({
    int? id,
    String? btnId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? profileImage,
    String? position,
    String? department,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      btnId: btnId ?? this.btnId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      position: position ?? this.position,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        btnId,
        firstName,
        lastName,
        email,
        phone,
        profileImage,
        position,
        department,
        isActive,
        createdAt,
        updatedAt,
      ];
}
