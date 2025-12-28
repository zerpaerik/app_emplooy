class Contract {
  final int id;
  final String contractName;
  final String customer;
  final String address;
  final String status;
  final int workersAssigned;
  final int clockedInToday;

  const Contract({
    required this.id,
    required this.contractName,
    required this.customer,
    required this.address,
    required this.status,
    required this.workersAssigned,
    required this.clockedInToday,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] ?? 0,
      contractName: json['contract_name'] ?? '',
      customer: json['customer'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? '',
      workersAssigned: json['workers_assigned'] ?? 0,
      clockedInToday: json['clocked_in_today'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_name': contractName,
      'customer': customer,
      'address': address,
      'status': status,
      'workers_assigned': workersAssigned,
      'clocked_in_today': clockedInToday,
    };
  }

  bool get isActive => status.toLowerCase() == 'active';

  Contract copyWith({
    int? id,
    String? contractName,
    String? customer,
    String? address,
    String? status,
    int? workersAssigned,
    int? clockedInToday,
  }) {
    return Contract(
      id: id ?? this.id,
      contractName: contractName ?? this.contractName,
      customer: customer ?? this.customer,
      address: address ?? this.address,
      status: status ?? this.status,
      workersAssigned: workersAssigned ?? this.workersAssigned,
      clockedInToday: clockedInToday ?? this.clockedInToday,
    );
  }
}
