import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../user/providers/user_provider.dart';

/// Tipos de dashboard disponibles
enum DashboardType {
  worker,
  business,
}

/// Provider para determinar el tipo de dashboard basado en el usuario
final dashboardTypeProvider = Provider<DashboardType>((ref) {
  final userState = ref.watch(userProvider);
  final user = userState.user;

  if (user == null) {
    return DashboardType.worker; // Default
  }

  // Lógica de validación de roles:
  // 1. Si role == "business" → Dashboard Business
  // 2. Si role != "business" pero location_list.isNotEmpty → Dashboard Business
  // 3. Si role != "business" y location_list.isEmpty → Dashboard Worker
  
  if (user.role == 'business') {
    return DashboardType.business;
  }
  
  if (user.role != 'business' && user.locationList.isNotEmpty) {
    return DashboardType.business;
  }
  
  return DashboardType.worker;
});

/// Provider para verificar si el usuario es business
final isBusinessProvider = Provider<bool>((ref) {
  final dashboardType = ref.watch(dashboardTypeProvider);
  return dashboardType == DashboardType.business;
});

/// Provider para obtener información específica del rol
final roleInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final userState = ref.watch(userProvider);
  final user = userState.user;
  final dashboardType = ref.watch(dashboardTypeProvider);

  if (user == null) {
    return {
      'type': 'worker',
      'hasLocations': false,
      'locationCount': 0,
      'role': 'worker',
    };
  }

  return {
    'type': dashboardType == DashboardType.business ? 'business' : 'worker',
    'hasLocations': user.locationList.isNotEmpty,
    'locationCount': user.locationList.length,
    'role': user.role,
    'btnId': user.btnId,
    'fullName': user.fullName,
    'contract': user.contract,
  };
});
