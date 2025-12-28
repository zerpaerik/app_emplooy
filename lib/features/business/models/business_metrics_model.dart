class BusinessMetrics {
  final int todayClockIns;
  final int yesterdayClockIns;
  final int todayAbsents;
  final int yesterdayAbsents;
  final List<LocationCoordinate> coordinates;

  const BusinessMetrics({
    required this.todayClockIns,
    required this.yesterdayClockIns,
    required this.todayAbsents,
    required this.yesterdayAbsents,
    required this.coordinates,
  });

  factory BusinessMetrics.fromJson(Map<String, dynamic> json) {
    return BusinessMetrics(
      todayClockIns: json['today_clock_ins'] ?? 0,
      yesterdayClockIns: json['yesterday_clock_ins'] ?? 0,
      todayAbsents: json['today_absents'] ?? 0,
      yesterdayAbsents: json['yesterday_absents'] ?? 0,
      coordinates: (json['coordinates'] as List?)
              ?.map((coord) => LocationCoordinate.fromJson(coord))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'today_clock_ins': todayClockIns,
      'yesterday_clock_ins': yesterdayClockIns,
      'today_absents': todayAbsents,
      'yesterday_absents': yesterdayAbsents,
      'coordinates': coordinates.map((coord) => coord.toJson()).toList(),
    };
  }

  // Getters calculados
  int get totalLocations => coordinates.length;
  
  bool get hasIncreasedClockIns => todayClockIns > yesterdayClockIns;
  
  bool get hasDecreasedAbsents => todayAbsents < yesterdayAbsents;
  
  bool get hasEqualClockIns => todayClockIns == yesterdayClockIns;
  
  bool get hasEqualAbsents => todayAbsents == yesterdayAbsents;

  BusinessMetrics copyWith({
    int? todayClockIns,
    int? yesterdayClockIns,
    int? todayAbsents,
    int? yesterdayAbsents,
    List<LocationCoordinate>? coordinates,
  }) {
    return BusinessMetrics(
      todayClockIns: todayClockIns ?? this.todayClockIns,
      yesterdayClockIns: yesterdayClockIns ?? this.yesterdayClockIns,
      todayAbsents: todayAbsents ?? this.todayAbsents,
      yesterdayAbsents: yesterdayAbsents ?? this.yesterdayAbsents,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}

class LocationCoordinate {
  final int id;
  final double lat;
  final double lon;
  final String contractName;
  final String address;
  final String customer;
  final int clockedIns;
  final int numberOfWorkers;
  final String workdayStatus;

  const LocationCoordinate({
    required this.id,
    required this.lat,
    required this.lon,
    required this.contractName,
    required this.address,
    required this.customer,
    required this.clockedIns,
    required this.numberOfWorkers,
    required this.workdayStatus,
  });

  factory LocationCoordinate.fromJson(Map<String, dynamic> json) {
    return LocationCoordinate(
      id: json['id'] ?? 0,
      lat: (json['lat'] ?? 0.0).toDouble(),
      lon: (json['lon'] ?? 0.0).toDouble(),
      contractName: json['contract_name'] ?? '',
      address: json['address'] ?? '',
      customer: json['customer'] ?? '',
      clockedIns: json['clocked_ins'] ?? 0,
      numberOfWorkers: json['number_of_workers'] ?? 0,
      workdayStatus: json['workday_status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lat': lat,
      'lon': lon,
      'contract_name': contractName,
      'address': address,
      'customer': customer,
      'clocked_ins': clockedIns,
      'number_of_workers': numberOfWorkers,
      'workday_status': workdayStatus,
    };
  }

  LocationCoordinate copyWith({
    int? id,
    double? lat,
    double? lon,
    String? contractName,
    String? address,
    String? customer,
    int? clockedIns,
    int? numberOfWorkers,
    String? workdayStatus,
  }) {
    return LocationCoordinate(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      contractName: contractName ?? this.contractName,
      address: address ?? this.address,
      customer: customer ?? this.customer,
      clockedIns: clockedIns ?? this.clockedIns,
      numberOfWorkers: numberOfWorkers ?? this.numberOfWorkers,
      workdayStatus: workdayStatus ?? this.workdayStatus,
    );
  }
}
