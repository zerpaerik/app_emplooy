class Project {
  final int id;
  final String name;
  final String customer;
  final int todayClockIns;
  final int todayAbsents;
  final int yesterdayWh;

  const Project({
    required this.id,
    required this.name,
    required this.customer,
    required this.todayClockIns,
    required this.todayAbsents,
    required this.yesterdayWh,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      customer: json['customer'] ?? '',
      todayClockIns: json['today_clock_ins'] ?? 0,
      todayAbsents: json['today_absents'] ?? 0,
      yesterdayWh: json['yesterday_wh'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'customer': customer,
      'today_clock_ins': todayClockIns,
      'today_absents': todayAbsents,
      'yesterday_wh': yesterdayWh,
    };
  }

  Project copyWith({
    int? id,
    String? name,
    String? customer,
    int? todayClockIns,
    int? todayAbsents,
    int? yesterdayWh,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      customer: customer ?? this.customer,
      todayClockIns: todayClockIns ?? this.todayClockIns,
      todayAbsents: todayAbsents ?? this.todayAbsents,
      yesterdayWh: yesterdayWh ?? this.yesterdayWh,
    );
  }
}
