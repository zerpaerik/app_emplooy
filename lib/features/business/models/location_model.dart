class Location {
  final int id;
  final String name;
  final String firstAddress;
  final String? verifiedAddress;
  final String projectName;
  final int todayClockIns;
  final int todayAbsents;
  final int yesterdayWh;
  final List<SubLocation>? subLocations;

  const Location({
    required this.id,
    required this.name,
    required this.firstAddress,
    this.verifiedAddress,
    required this.projectName,
    required this.todayClockIns,
    required this.todayAbsents,
    required this.yesterdayWh,
    this.subLocations,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      firstAddress: json['first_address'] ?? '',
      verifiedAddress: json['verified_address'],
      projectName: json['project_name'] ?? '',
      todayClockIns: json['today_clock_ins'] ?? 0,
      todayAbsents: json['today_absents'] ?? 0,
      yesterdayWh: json['yesterday_wh'] ?? 0,
      subLocations: (json['sub_locations'] as List?)
          ?.map((sub) => SubLocation.fromJson(sub))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'first_address': firstAddress,
      'verified_address': verifiedAddress,
      'project_name': projectName,
      'today_clock_ins': todayClockIns,
      'today_absents': todayAbsents,
      'yesterday_wh': yesterdayWh,
      'sub_locations': subLocations?.map((sub) => sub.toJson()).toList(),
    };
  }

  bool get hasSubLocations => subLocations != null && subLocations!.isNotEmpty;

  Location copyWith({
    int? id,
    String? name,
    String? firstAddress,
    String? verifiedAddress,
    String? projectName,
    int? todayClockIns,
    int? todayAbsents,
    int? yesterdayWh,
    List<SubLocation>? subLocations,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      firstAddress: firstAddress ?? this.firstAddress,
      verifiedAddress: verifiedAddress ?? this.verifiedAddress,
      projectName: projectName ?? this.projectName,
      todayClockIns: todayClockIns ?? this.todayClockIns,
      todayAbsents: todayAbsents ?? this.todayAbsents,
      yesterdayWh: yesterdayWh ?? this.yesterdayWh,
      subLocations: subLocations ?? this.subLocations,
    );
  }
}

class SubLocation {
  final int id;
  final String name;
  final String address;

  const SubLocation({
    required this.id,
    required this.name,
    required this.address,
  });

  factory SubLocation.fromJson(Map<String, dynamic> json) {
    return SubLocation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
    };
  }
}
