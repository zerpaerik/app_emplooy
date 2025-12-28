import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dashboard_api_service.dart';

// Estado del Dashboard
class DashboardState {
  final Map<String, dynamic>? workedHours;
  final Map<String, dynamic>? currentContract;
  final int? contractStatusCode;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.workedHours,
    this.currentContract,
    this.contractStatusCode,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    Map<String, dynamic>? workedHours,
    Map<String, dynamic>? currentContract,
    int? contractStatusCode,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      workedHours: workedHours ?? this.workedHours,
      currentContract: currentContract ?? this.currentContract,
      contractStatusCode: contractStatusCode ?? this.contractStatusCode,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Provider del Dashboard
class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardApiService _apiService;

  DashboardNotifier(this._apiService) : super(DashboardState());

  // Cargar datos del dashboard
  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Cargar horas trabajadas y contrato en paralelo
      final results = await Future.wait([
        _apiService.getWorkedHours(),
        _apiService.getCurrentContract(),
      ]);

      final hoursResult = results[0];
      final contractResult = results[1];

      state = state.copyWith(
        workedHours: hoursResult['success'] == true ? hoursResult['data'] : null,
        currentContract: contractResult['success'] == true ? contractResult['data'] : null,
        contractStatusCode: contractResult['statusCode'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading dashboard data: $e',
      );
    }
  }

  // Refrescar solo las horas trabajadas
  Future<void> refreshWorkedHours() async {
    try {
      final result = await _apiService.getWorkedHours();
      if (result['success'] == true) {
        state = state.copyWith(workedHours: result['data']);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error refreshing hours: $e');
    }
  }

  // Refrescar solo el contrato
  Future<void> refreshContract() async {
    try {
      final result = await _apiService.getCurrentContract();
      state = state.copyWith(
        currentContract: result['success'] == true ? result['data'] : null,
        contractStatusCode: result['statusCode'],
      );
    } catch (e) {
      state = state.copyWith(error: 'Error refreshing contract: $e');
    }
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final apiService = ref.watch(dashboardApiServiceProvider);
  return DashboardNotifier(apiService);
});
