class UserModel {
  final String token;
  final int userId;
  final String firstName;
  final String lastName;
  final String birthDate;
  final String btnId;
  final String? profileImage;
  final String email;
  final bool active;
  final bool hasCity;
  final bool hasDependentsNumber;
  final bool hasProfileImage;
  final int notificationsUnopen;
  final int contract;
  final String role;
  final String idType;
  final String contactFirstName;
  final String? taxDocFile;
  final String bloodType;
  final int legalDocumentsCount;
  final List<dynamic>? projectList;
  final List<dynamic> locationList;
  final List<dynamic>? contractList;
  final String referralCode;

  const UserModel({
    required this.token,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.btnId,
    this.profileImage,
    required this.email,
    required this.active,
    required this.hasCity,
    required this.hasDependentsNumber,
    required this.hasProfileImage,
    required this.notificationsUnopen,
    required this.contract,
    required this.role,
    required this.idType,
    required this.contactFirstName,
    this.taxDocFile,
    required this.bloodType,
    required this.legalDocumentsCount,
    this.projectList,
    required this.locationList,
    this.contractList,
    required this.referralCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      token: json['token'] ?? '',
      userId: json['user_id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      birthDate: json['birth_date'] ?? '',
      btnId: json['btn_id'] ?? '',
      profileImage: json['profile_image'],
      email: json['email'] ?? '',
      active: json['active'] ?? false,
      hasCity: json['has_city'] ?? false,
      hasDependentsNumber: json['has_dependents_number'] ?? false,
      hasProfileImage: json['has_profile_image'] ?? false,
      notificationsUnopen: json['notifications_unopen'] ?? 0,
      contract: json['contract'] ?? 0,
      role: json['role'] ?? 'worker',
      idType: json['id_type'] ?? '',
      contactFirstName: json['contact_first_name'] ?? '',
      taxDocFile: json['tax_doc_file'],
      bloodType: json['blood_type'] ?? '',
      legalDocumentsCount: json['legal_documents_count'] ?? 0,
      projectList: json['project_list'],
      locationList: json['location_list'] ?? [],
      contractList: json['contract_list'],
      referralCode: json['referral_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate,
      'btn_id': btnId,
      'profile_image': profileImage,
      'email': email,
      'active': active,
      'has_city': hasCity,
      'has_dependents_number': hasDependentsNumber,
      'has_profile_image': hasProfileImage,
      'notifications_unopen': notificationsUnopen,
      'contract': contract,
      'role': role,
      'id_type': idType,
      'contact_first_name': contactFirstName,
      'tax_doc_file': taxDocFile,
      'blood_type': bloodType,
      'legal_documents_count': legalDocumentsCount,
      'project_list': projectList,
      'location_list': locationList,
      'contract_list': contractList,
      'referral_code': referralCode,
    };
  }

  UserModel copyWith({
    String? token,
    int? userId,
    String? firstName,
    String? lastName,
    String? birthDate,
    String? btnId,
    String? profileImage,
    String? email,
    bool? active,
    bool? hasCity,
    bool? hasDependentsNumber,
    bool? hasProfileImage,
    int? notificationsUnopen,
    int? contract,
    String? role,
    String? idType,
    String? contactFirstName,
    String? taxDocFile,
    String? bloodType,
    int? legalDocumentsCount,
    List<dynamic>? projectList,
    List<dynamic>? locationList,
    List<dynamic>? contractList,
    String? referralCode,
  }) {
    return UserModel(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      btnId: btnId ?? this.btnId,
      profileImage: profileImage ?? this.profileImage,
      email: email ?? this.email,
      active: active ?? this.active,
      hasCity: hasCity ?? this.hasCity,
      hasDependentsNumber: hasDependentsNumber ?? this.hasDependentsNumber,
      hasProfileImage: hasProfileImage ?? this.hasProfileImage,
      notificationsUnopen: notificationsUnopen ?? this.notificationsUnopen,
      contract: contract ?? this.contract,
      role: role ?? this.role,
      idType: idType ?? this.idType,
      contactFirstName: contactFirstName ?? this.contactFirstName,
      taxDocFile: taxDocFile ?? this.taxDocFile,
      bloodType: bloodType ?? this.bloodType,
      legalDocumentsCount: legalDocumentsCount ?? this.legalDocumentsCount,
      projectList: projectList ?? this.projectList,
      locationList: locationList ?? this.locationList,
      contractList: contractList ?? this.contractList,
      referralCode: referralCode ?? this.referralCode,
    );
  }

  /// Getter para compatibilidad con id
  int get id => userId;

  /// Determina si el usuario es business basado en el rol y location_list
  bool get isBusiness {
    return role == 'business' || 
           (role != 'business' && locationList.isNotEmpty);
  }

  /// Obtiene el nombre completo del usuario
  String get fullName => '$firstName $lastName';

  /// Verifica si el usuario tiene perfil completo
  bool get hasCompleteProfile {
    return hasProfileImage && hasCity && profileImage != null;
  }
}
