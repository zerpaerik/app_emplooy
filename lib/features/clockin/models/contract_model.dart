class ContractModel {
  final int id;
  final String contractName;
  final String? contractDescription;
  final bool contractTemp;
  final int? totalWorkers;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final Map<String, dynamic>? additionalData;

  ContractModel({
    required this.id,
    required this.contractName,
    this.contractDescription,
    required this.contractTemp,
    this.totalWorkers,
    this.location,
    this.startDate,
    this.endDate,
    this.status,
    this.additionalData,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['id'] ?? json['contract_id'] ?? 0,
      contractName: json['contract_name'] ?? json['name'] ?? 'Unknown Contract',
      contractDescription: json['contract_description'] ?? json['description'],
      contractTemp: json['contract_temp'] ?? false,
      totalWorkers: json['total_workers'] ?? json['workers_count'],
      location: json['location'] ?? json['contract_location'],
      startDate: json['start_date'] != null 
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.tryParse(json['end_date'].toString())
          : null,
      status: json['status'],
      additionalData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_name': contractName,
      'contract_description': contractDescription,
      'contract_temp': contractTemp,
      'total_workers': totalWorkers,
      'location': location,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
    };
  }

  ContractModel copyWith({
    int? id,
    String? contractName,
    String? contractDescription,
    bool? contractTemp,
    int? totalWorkers,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    Map<String, dynamic>? additionalData,
  }) {
    return ContractModel(
      id: id ?? this.id,
      contractName: contractName ?? this.contractName,
      contractDescription: contractDescription ?? this.contractDescription,
      contractTemp: contractTemp ?? this.contractTemp,
      totalWorkers: totalWorkers ?? this.totalWorkers,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  bool get isActive => status?.toLowerCase() == 'active';
  bool get requiresTemperature => contractTemp;
}
