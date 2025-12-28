import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workday_report_model.dart';
import '../services/workday_reports_api_service.dart';

// Estado del módulo de Workday Reports
class WorkdayReportsState {
  final List<WorkdayReportModel> reports;
  final WorkdayReportModel? currentReport;
  final bool isLoading;
  final String? error;
  
  // Estado del formulario
  final int currentStep;
  final WorkdayReportModel? draftReport;
  final int? reportId; // ID del reporte creado en Step 0
  final int? workdayId; // ID de la jornada actual
  final bool? hasWorkday; // Si hubo jornada o no
  
  // Tiempos de clock-in/clock-out
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  
  // Datos auxiliares para el formulario
  final List<Map<String, dynamic>> availableWorkers;
  final List<Map<String, dynamic>> availableDrivers;
  final List<Map<String, dynamic>> absentWorkers;
  final List<Map<String, dynamic>> availableVehicles;

  const WorkdayReportsState({
    this.reports = const [],
    this.currentReport,
    this.isLoading = false,
    this.error,
    this.currentStep = 0,
    this.draftReport,
    this.reportId,
    this.workdayId,
    this.hasWorkday,
    this.clockInTime,
    this.clockOutTime,
    this.availableWorkers = const [],
    this.availableDrivers = const [],
    this.absentWorkers = const [],
    this.availableVehicles = const [],
  });

  WorkdayReportsState copyWith({
    List<WorkdayReportModel>? reports,
    WorkdayReportModel? currentReport,
    bool? isLoading,
    String? error,
    int? currentStep,
    WorkdayReportModel? draftReport,
    int? reportId,
    int? workdayId,
    bool? hasWorkday,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    List<Map<String, dynamic>>? availableWorkers,
    List<Map<String, dynamic>>? availableDrivers,
    List<Map<String, dynamic>>? absentWorkers,
    List<Map<String, dynamic>>? availableVehicles,
  }) {
    return WorkdayReportsState(
      reports: reports ?? this.reports,
      currentReport: currentReport ?? this.currentReport,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentStep: currentStep ?? this.currentStep,
      draftReport: draftReport ?? this.draftReport,
      reportId: reportId ?? this.reportId,
      workdayId: workdayId ?? this.workdayId,
      hasWorkday: hasWorkday ?? this.hasWorkday,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      availableWorkers: availableWorkers ?? this.availableWorkers,
      availableDrivers: availableDrivers ?? this.availableDrivers,
      absentWorkers: absentWorkers ?? this.absentWorkers,
      availableVehicles: availableVehicles ?? this.availableVehicles,
    );
  }
}

// Notifier para manejar el estado de Workday Reports
class WorkdayReportsNotifier extends StateNotifier<WorkdayReportsState> {
  final WorkdayReportsApiService _apiService;

  WorkdayReportsNotifier(this._apiService) : super(const WorkdayReportsState());

  // Cargar reportes de un contrato
  Future<void> loadReports(int contractId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final reports = await _apiService.getReports(contractId);
      state = state.copyWith(
        reports: reports,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Cargar detalle de un reporte
  Future<void> loadReportDetail(int reportId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final report = await _apiService.getReportDetail(reportId);
      state = state.copyWith(
        currentReport: report,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Inicializar nuevo reporte
  Future<void> initializeNewReport(int workdayId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Cargar datos necesarios para el formulario
      final workers = await _apiService.getClockedWorkers(workdayId);
      final drivers = await _apiService.getClockedDrivers(workdayId);
      final absent = await _apiService.getAbsentWorkers(workdayId);

      // Crear reporte draft
      final draftReport = WorkdayReportModel(
        workdayId: workdayId,
        reportDate: DateTime.now(),
        status: 'draft',
      );

      state = state.copyWith(
        draftReport: draftReport,
        workdayId: workdayId,
        availableWorkers: workers,
        availableDrivers: drivers,
        absentWorkers: absent,
        currentStep: 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Actualizar draft del reporte
  void updateDraftReport(WorkdayReportModel report) {
    state = state.copyWith(draftReport: report);
  }

  // Navegar al siguiente step
  void nextStep() {
    if (state.currentStep < 4) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  // Navegar al step anterior
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  // Ir a un step específico
  void goToStep(int step) {
    if (step >= 0 && step <= 4) {
      state = state.copyWith(currentStep: step);
    }
  }

  // Guardar reporte (crear o actualizar)
  Future<bool> saveReport() async {
    if (state.draftReport == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final report = state.draftReport!.copyWith(status: 'submitted');
      
      WorkdayReportModel? savedReport;
      if (report.id == null) {
        // Crear nuevo reporte
        savedReport = await _apiService.createReport(report);
      } else {
        // Actualizar reporte existente
        savedReport = await _apiService.updateReport(report.id!, report);
      }

      state = state.copyWith(
        currentReport: savedReport,
        draftReport: null,
        currentStep: 0,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Eliminar reporte
  Future<bool> deleteReport(int reportId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _apiService.deleteReport(reportId);
      
      if (success) {
        // Remover de la lista
        final updatedReports = state.reports.where((r) => r.id != reportId).toList();
        state = state.copyWith(
          reports: updatedReports,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete report',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Cargar vehículos disponibles
  Future<void> loadAvailableVehicles(int reportId) async {
    try {
      final vehicles = await _apiService.getAvailableVehicles(reportId);
      state = state.copyWith(availableVehicles: vehicles);
    } catch (e) {
      print('Error loading vehicles: $e');
    }
  }

  // Limpiar estado
  void clearState() {
    state = const WorkdayReportsState();
  }

  // Resetear formulario
  void resetForm() {
    state = state.copyWith(
      draftReport: null,
      currentStep: 0,
      availableWorkers: [],
      availableDrivers: [],
      absentWorkers: [],
      availableVehicles: [],
    );
  }

  // NUEVOS MÉTODOS PARA CREAR Y ACTUALIZAR REPORTES

  // Step 0: Crear reporte base
  Future<int?> createReportBase(int workdayId, bool hadWorkday) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final reportId = await _apiService.createReportBase(workdayId, hadWorkday);
      
      state = state.copyWith(
        reportId: reportId,
        workdayId: workdayId,
        hasWorkday: hadWorkday,
        isLoading: false,
      );

      return reportId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  // Step 1: Actualizar lunch
  Future<bool> updateReportLunch(int reportId, String? duration) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.updateReportLunch(reportId, duration);
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Step 2: Actualizar standby
  Future<bool> updateReportStandby(int reportId, String? duration) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.updateReportStandby(reportId, duration);
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Step 3: Actualizar travel
  Future<bool> updateReportTravel(int reportId, String? duration) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.updateReportTravel(reportId, duration);
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Step 4: Actualizar comments
  Future<bool> updateReportComments(int reportId, String? comments) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.updateReportComments(reportId, comments);
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Guardar reportId en el state
  void setReportId(int reportId) {
    state = state.copyWith(reportId: reportId);
  }

  // Guardar workdayId en el state
  void setWorkdayId(int workdayId) {
    state = state.copyWith(workdayId: workdayId);
  }

  // Finalizar jornada después de completar el reporte
  Future<bool> finalizeWorkday(int workdayId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.finalizeWorkday(workdayId);
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

// Provider del servicio API
final workdayReportsApiServiceProvider = Provider<WorkdayReportsApiService>((ref) {
  return WorkdayReportsApiService();
});

// Provider del estado de Workday Reports
final workdayReportsProvider = StateNotifierProvider<WorkdayReportsNotifier, WorkdayReportsState>((ref) {
  final apiService = ref.watch(workdayReportsApiServiceProvider);
  return WorkdayReportsNotifier(apiService);
});
