import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client.dart';
import '../models/business_metrics_model.dart';

/// Estado del Business Provider
class BusinessState {
  final bool isLoading;
  final BusinessMetrics? metrics;
  final String? error;
  final String selectedStatus;
  final LocationCoordinate? selectedLocation;

  const BusinessState({
    this.isLoading = false,
    this.metrics,
    this.error,
    this.selectedStatus = 'active',
    this.selectedLocation,
  });

  BusinessState copyWith({
    bool? isLoading,
    BusinessMetrics? metrics,
    String? error,
    String? selectedStatus,
    LocationCoordinate? selectedLocation,
  }) {
    return BusinessState(
      isLoading: isLoading ?? this.isLoading,
      metrics: metrics ?? this.metrics,
      error: error,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedLocation: selectedLocation ?? this.selectedLocation,
    );
  }
}

/// Provider de Business
final businessProvider = StateNotifierProvider<BusinessNotifier, BusinessState>((ref) {
  return BusinessNotifier();
});

class BusinessNotifier extends StateNotifier<BusinessState> {
  BusinessNotifier() : super(const BusinessState()) {
    // Cargar métricas al inicializar
    fetchMetrics();
  }

  final _httpClient = HttpClient.instance;

  /// Obtener métricas del business desde el servidor
  Future<void> fetchMetrics({String? status}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final statusFilter = status ?? state.selectedStatus;
      final response = await _httpClient.get(
        '/api/v-1/business/metrics?status=$statusFilter',
        requiresAuth: true,
      );

      if (_httpClient.isSuccessful(response)) {
        final data = _httpClient.parseResponse(response);
        if (data != null) {
          final metrics = BusinessMetrics.fromJson(data);
          
          state = state.copyWith(
            isLoading: false,
            metrics: metrics,
            selectedStatus: statusFilter,
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load business metrics',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Refrescar métricas
  Future<void> refreshMetrics() async {
    await fetchMetrics(status: state.selectedStatus);
  }

  /// Cambiar filtro de status
  Future<void> changeStatus(String status) async {
    if (status != state.selectedStatus) {
      await fetchMetrics(status: status);
    }
  }

  /// Seleccionar una ubicación del mapa
  void selectLocation(LocationCoordinate? location) {
    state = state.copyWith(selectedLocation: location);
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
