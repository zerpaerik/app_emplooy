class UserModules {
  final bool clockInModule;
  final bool clockOutModule;
  final bool expensesModule;
  final bool warningsModule;
  final bool workdayReportsModule;
  final String role;

  const UserModules({
    required this.clockInModule,
    required this.clockOutModule,
    required this.expensesModule,
    required this.warningsModule,
    required this.workdayReportsModule,
    required this.role,
  });

  factory UserModules.fromJson(Map<String, dynamic> json) {
    return UserModules(
      clockInModule: json['clock_in_module'] ?? false,
      clockOutModule: json['clock_out_module'] ?? false,
      expensesModule: json['expenses_module'] ?? false,
      warningsModule: json['warnings_module'] ?? false,
      workdayReportsModule: json['workday_reports_module'] ?? false,
      role: json['role'] ?? 'worker',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clock_in_module': clockInModule,
      'clock_out_module': clockOutModule,
      'expenses_module': expensesModule,
      'warnings_module': warningsModule,
      'workday_reports_module': workdayReportsModule,
      'role': role,
    };
  }

  UserModules copyWith({
    bool? clockInModule,
    bool? clockOutModule,
    bool? expensesModule,
    bool? warningsModule,
    bool? workdayReportsModule,
    String? role,
  }) {
    return UserModules(
      clockInModule: clockInModule ?? this.clockInModule,
      clockOutModule: clockOutModule ?? this.clockOutModule,
      expensesModule: expensesModule ?? this.expensesModule,
      warningsModule: warningsModule ?? this.warningsModule,
      workdayReportsModule: workdayReportsModule ?? this.workdayReportsModule,
      role: role ?? this.role,
    );
  }
}

/// Módulos por defecto para diferentes roles
class DefaultModules {
  static UserModules forRole(String role) {
    switch (role) {
      case 'business':
      case 'customer':
        return const UserModules(
          clockInModule: false,
          clockOutModule: false,
          expensesModule: false,
          warningsModule: false,
          workdayReportsModule: false,
          role: 'business',
        );
      case 'supervisor':
      case 'is_lead':
      case 'lead':
        return const UserModules(
          clockInModule: true,
          clockOutModule: true,
          expensesModule: true,
          warningsModule: true,
          workdayReportsModule: true,
          role: 'supervisor',
        );
      default: // worker
        return const UserModules(
          clockInModule: true,
          clockOutModule: true,
          expensesModule: false,
          warningsModule: false,
          workdayReportsModule: false,
          role: 'worker',
        );
    }
  }
}
