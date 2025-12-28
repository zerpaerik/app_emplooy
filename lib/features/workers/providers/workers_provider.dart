import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/worker_model.dart';
import '../services/workers_api_service.dart';

// Estado del módulo de Workers
class WorkersState {
  final List<WorkerModel> workers;
  final List<WorkerModel> filteredWorkers;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const WorkersState({
    this.workers = const [],
    this.filteredWorkers = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  WorkersState copyWith({
    List<WorkerModel>? workers,
    List<WorkerModel>? filteredWorkers,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return WorkersState(
      workers: workers ?? this.workers,
      filteredWorkers: filteredWorkers ?? this.filteredWorkers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// Notifier para manejar el estado de Workers
class WorkersNotifier extends StateNotifier<WorkersState> {
  final WorkersApiService _apiService;

  WorkersNotifier(this._apiService) : super(const WorkersState());

  // Cargar workers de un contrato
  Future<void> loadWorkers(int contractId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final workers = await _apiService.getWorkers(contractId);
      state = state.copyWith(
        workers: workers,
        filteredWorkers: workers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Buscar workers por nombre o BTN ID
  void searchWorkers(String query) {
    state = state.copyWith(searchQuery: query);

    if (query.isEmpty) {
      state = state.copyWith(filteredWorkers: state.workers);
      return;
    }

    final filtered = state.workers.where((worker) {
      final fullName = worker.fullName.toLowerCase();
      final btnId = worker.btnId.toLowerCase();
      final searchLower = query.toLowerCase();

      return fullName.contains(searchLower) || btnId.contains(searchLower);
    }).toList();

    state = state.copyWith(filteredWorkers: filtered);
  }

  // Refrescar lista de workers
  Future<void> refreshWorkers(int contractId) async {
    await loadWorkers(contractId);
  }

  // Limpiar búsqueda
  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      filteredWorkers: state.workers,
    );
  }
}

// Provider del servicio API
final workersApiServiceProvider = Provider<WorkersApiService>((ref) {
  return WorkersApiService();
});

// Provider del estado de Workers
final workersProvider = StateNotifierProvider<WorkersNotifier, WorkersState>((ref) {
  final apiService = ref.watch(workersApiServiceProvider);
  return WorkersNotifier(apiService);
});
