import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/worker_report_model.dart';
import '../services/worker_report_service.dart';

final workerReportServiceProvider = Provider<WorkerReportService>((ref) {
  return WorkerReportService();
});

final workerReportProvider = StateNotifierProvider.family.autoDispose<
    WorkerReportNotifier,
    WorkerReportState,
    WorkerReportParams>((ref, params) {
  final service = ref.watch(workerReportServiceProvider);
  return WorkerReportNotifier(service, params);
});

class WorkerReportParams {
  final int workdayId;
  final int reportId;

  WorkerReportParams({
    required this.workdayId,
    required this.reportId,
  });
}

class WorkerReportState {
  final Map<WorkerReportCategory, List<WorkerReportModel>> workersByCategory;
  final bool isLoading;
  final String? error;
  final List<int> selectedWorkerIds;

  WorkerReportState({
    required this.workersByCategory,
    this.isLoading = false,
    this.error,
    this.selectedWorkerIds = const [],
  });

  WorkerReportState copyWith({
    Map<WorkerReportCategory, List<WorkerReportModel>>? workersByCategory,
    bool? isLoading,
    String? error,
    List<int>? selectedWorkerIds,
  }) {
    return WorkerReportState(
      workersByCategory: workersByCategory ?? this.workersByCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedWorkerIds: selectedWorkerIds ?? this.selectedWorkerIds,
    );
  }

  int get onTimeCount => workersByCategory[WorkerReportCategory.onTime]?.length ?? 0;
  int get lateCount => workersByCategory[WorkerReportCategory.late]?.length ?? 0;
  int get reviewedCount => workersByCategory[WorkerReportCategory.reviewed]?.length ?? 0;
  int get standbyCount => workersByCategory[WorkerReportCategory.standby]?.length ?? 0;
  int get totalWorkers => onTimeCount + lateCount + reviewedCount;

  bool get hasUnreviewedLateWorkers => lateCount > 0;
  bool get canSendReport => !hasUnreviewedLateWorkers;
}

class WorkerReportNotifier extends StateNotifier<WorkerReportState> {
  final WorkerReportService _service;
  final WorkerReportParams _params;

  WorkerReportNotifier(this._service, this._params)
      : super(WorkerReportState(
          workersByCategory: {
            WorkerReportCategory.onTime: [],
            WorkerReportCategory.late: [],
            WorkerReportCategory.reviewed: [],
            WorkerReportCategory.standby: [],
          },
        )) {
    loadWorkers();
  }

  Future<void> loadWorkers() async {
    print('🔄 Loading workers for workday: ${_params.workdayId}, report: ${_params.reportId}');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final workersByCategory = await _service.getAllWorkersByCategory(
        _params.workdayId,
        _params.reportId,
      );

      print('✅ Workers loaded successfully:');
      print('   On-Time: ${workersByCategory[WorkerReportCategory.onTime]?.length ?? 0}');
      print('   Late: ${workersByCategory[WorkerReportCategory.late]?.length ?? 0}');
      print('   Reviewed: ${workersByCategory[WorkerReportCategory.reviewed]?.length ?? 0}');
      print('   Standby: ${workersByCategory[WorkerReportCategory.standby]?.length ?? 0}');

      state = state.copyWith(
        workersByCategory: workersByCategory,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      print('❌ Error loading workers: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading workers: $e',
      );
    }
  }

  Future<bool> editWorker({
    required int workerId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final success = await _service.editWorker(
        workdayId: _params.workdayId,
        workerId: workerId,
        updates: updates,
      );

      if (success) {
        await loadWorkers();
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: 'Error editing worker: $e');
      return false;
    }
  }

  Future<bool> editMultipleWorkers({
    required Map<String, dynamic> updates,
  }) async {
    if (state.selectedWorkerIds.isEmpty) {
      state = state.copyWith(error: 'No workers selected');
      return false;
    }

    try {
      final success = await _service.editMultipleWorkers(
        workdayId: _params.workdayId,
        workerIds: state.selectedWorkerIds,
        updates: updates,
      );

      if (success) {
        state = state.copyWith(selectedWorkerIds: []);
        await loadWorkers();
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: 'Error editing workers: $e');
      return false;
    }
  }

  void toggleWorkerSelection(int workerId) {
    final currentSelection = List<int>.from(state.selectedWorkerIds);
    
    if (currentSelection.contains(workerId)) {
      currentSelection.remove(workerId);
    } else {
      currentSelection.add(workerId);
    }

    state = state.copyWith(selectedWorkerIds: currentSelection);
  }

  void clearSelection() {
    state = state.copyWith(selectedWorkerIds: []);
  }

  void selectAll(WorkerReportCategory category) {
    final workers = state.workersByCategory[category] ?? [];
    final workerIds = workers.map((w) => w.workerId).toList();
    state = state.copyWith(selectedWorkerIds: workerIds);
  }

  Future<bool> finalizeWorkday() async {
    if (state.hasUnreviewedLateWorkers) {
      state = state.copyWith(
        error: 'Cannot finalize workday with unreviewed late workers',
      );
      return false;
    }

    try {
      final success = await _service.finalizeWorkday(_params.workdayId);
      
      if (success) {
        await loadWorkers();
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: 'Error finalizing workday: $e');
      return false;
    }
  }

  Future<bool> sendReport() async {
    if (state.hasUnreviewedLateWorkers) {
      state = state.copyWith(
        error: 'Cannot send report with unreviewed late workers',
      );
      return false;
    }

    try {
      final success = await _service.sendReport(_params.reportId);
      return success;
    } catch (e) {
      state = state.copyWith(error: 'Error sending report: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
