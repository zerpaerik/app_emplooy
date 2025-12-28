import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clockin_session_model.dart';
import '../models/worker_scan_model.dart';
import '../models/workday_model.dart';
import '../services/clockin_api_service.dart';
import '../services/location_service.dart';
import '../services/clockin_validation_service.dart';
import '../../user/providers/user_provider.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/local_database.dart';

// Estado del provider de clock-in
class ClockinState {
  final ClockinSessionModel? session;
  final bool isLoading;
  final String? error;
  final bool isLocationEnabled;

  const ClockinState({
    this.session,
    this.isLoading = false,
    this.error,
    this.isLocationEnabled = false,
  });

  ClockinState copyWith({
    ClockinSessionModel? session,
    bool? isLoading,
    String? error,
    bool? isLocationEnabled,
  }) {
    return ClockinState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
    );
  }
}

// Notifier para manejar el estado de clock-in
class ClockinNotifier extends StateNotifier<ClockinState> {
  final ClockinApiService _apiService;
  final LocationService _locationService;
  final Ref _ref;

  ClockinNotifier(this._apiService, this._locationService, this._ref) 
      : super(const ClockinState()) {
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      await LocalDatabase.instance.database;
      print('✅ Local database initialized');
    } catch (e) {
      print('❌ Error initializing database: $e');
    }
  }

  // Inicializar sesión de clock-in
  Future<void> initializeSession(int contractId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Verificar permisos de ubicación (no bloquear si falla)
      bool locationEnabled = false;
      try {
        locationEnabled = await _locationService.checkLocationPermission();
      } catch (e) {
        print('Location permission check failed: $e');
        locationEnabled = false; // Continuar sin ubicación
      }
      
      // Obtener workday actual del servidor
      WorkdayModel? workday;
      try {
        workday = await _apiService.getCurrentWorkday(contractId);
        print('Workday obtenido del servidor: ${workday?.id}, status: ${workday?.status}');
      } catch (e) {
        print('No workday found, will create new one: $e');
        workday = null;
      }
      
      // Obtener lista de workers del contrato
      List<WorkerScanModel> workers = [];
      try {
        workers = await _apiService.getContractWorkers(contractId);
      } catch (e) {
        print('Error getting workers: $e');
        workers = [];
      }
      
      // Verificar si supervisor ya hizo clock-in (solo si hay workday activo)
      bool supervisorHasClockin = false;
      if (workday != null && !workday.isNotStarted) {
        try {
          supervisorHasClockin = await checkSupervisorClockin();
          print('Supervisor has clock-in: $supervisorHasClockin');
        } catch (e) {
          print('Error checking supervisor clock-in: $e');
          supervisorHasClockin = false;
        }
      }
      
      // Crear sesión inicial
      final session = ClockinSessionModel(
        workday: workday,
        workers: workers,
        contractId: contractId.toString(),
        status: workday == null || workday.isNotStarted 
            ? ClockinStatus.setup 
            : ClockinStatus.active,
        supervisorHasClockin: supervisorHasClockin,
      );

      state = state.copyWith(
        session: session,
        isLoading: false,
        isLocationEnabled: locationEnabled,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Configurar workday (fecha, hora, temperatura)
  Future<void> setupWorkday({
    required DateTime entryTime,
    required String temperature,
    required bool isAutomaticMode,
  }) async {
    if (state.session == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _ref.read(userProvider).user;
      if (user == null) throw Exception('User not found');

      // Obtener ubicación actual (sin bloquear si falla)
      // Usar coordenadas por defecto si no se puede obtener ubicación (como en Worker)
      String locationString = '18.4655 -66.1057'; // San Juan, PR por defecto
      try {
        final location = await _locationService.getCurrentLocation();
        if (location != null) {
          locationString = '${location.latitude} ${location.longitude}';
        }
      } catch (e) {
        print('Location error: $e');
        // Mantener coordenadas por defecto
      }

      // Llamar al API real como en worker
      final updatedWorkday = await _apiService.setupWorkday(
        contractId: int.parse(state.session!.contractId!),
        entryTime: entryTime,
        temperature: temperature,
        location: locationString,
        isAutomaticMode: isAutomaticMode,
      );

      // Obtener workers actualizados del contrato
      List<WorkerScanModel> workers = [];
      try {
        workers = await _apiService.getContractWorkers(int.parse(state.session!.contractId!));
      } catch (e) {
        print('Error getting workers after setup: $e');
        workers = state.session!.workers;
      }

      // Guardar workday ID en BD local
      await DatabaseHelper.updateWorkdayId(updatedWorkday.id!);
      
      // Guardar default_init (hora seleccionada por usuario) en BD local
      await DatabaseHelper.updateDefaultInit(entryTime);
      print('✅ Saved default_init: $entryTime (hora seleccionada por usuario)');

      // Crear sesión de supervisor en BD local
      final sessionId = await ClockInValidationService.getOrCreateSession(
        workdayId: updatedWorkday.id!,
        supervisorId: user.btnId,
        supervisorName: '${user.firstName} ${user.lastName}',
        sessionStartTime: entryTime,
        isAutoMode: isAutomaticMode,
      );
      print('✅ Created session with ult_clock = DateTime.now() (hora actual del momento)');

      print('✅ Clock-in session created: $sessionId for supervisor ${user.btnId}');

      // Actualizar sesión con workday creado
      final updatedSession = state.session!.copyWith(
        workday: updatedWorkday,
        workers: workers,
        status: ClockinStatus.active,
        isAutomaticMode: isAutomaticMode,
        startedAt: DateTime.now(),
        supervisorId: user.id,
        currentLocation: locationString,
      );

      state = state.copyWith(
        session: updatedSession,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Escanear worker
  Future<void> scanWorker(String qrCode) async {
    if (state.session == null || !state.session!.canStartScanning) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _ref.read(userProvider).user;
      if (user == null) throw Exception('User not found');

      // Obtener ubicación actual
      final location = await _locationService.getCurrentLocation();
      final locationString = location != null 
          ? '${location.latitude} ${location.longitude}'
          : 'N/A';

      // Obtener sesión actual de BD local
      final currentSessionMap = await DatabaseHelper.getCurrentSession('IN');
      if (currentSessionMap == null) {
        throw Exception('No active session found. Please restart clock-in.');
      }
      final sessionId = currentSessionMap['id'] as int;

      // Validar y registrar scan en el servidor
      final scannedWorker = await _apiService.scanWorker(
        qrCode: qrCode,
        contractId: int.parse(state.session!.contractId!),
        workdayId: state.session!.workday!.id!,
        location: locationString,
        scannedByUserId: user.id,
      );

      // FIX 2: Usar hora ACTUAL del escaneo, no la hora de inicio de sesión
      final actualClockTime = DateTime.now();

      // Registrar worker en la sesión de BD local
      await ClockInValidationService.recordWorkerScan(
        sessionId: sessionId,
        workerId: scannedWorker.id,
        workerBtnId: scannedWorker.btnId ?? '',
        workerName: '${scannedWorker.firstName} ${scannedWorker.lastName}',
        clockTime: actualClockTime,
        location: locationString,
        supervisorId: user.btnId,
      );

      print('✅ Worker ${scannedWorker.firstName} registered in session $sessionId');

      // Actualizar sesión
      final updatedSession = state.session!.addScannedWorker(scannedWorker);

      state = state.copyWith(
        session: updatedSession,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Marcar worker como ausente
  Future<void> markWorkerAbsent({
    required int workerId,
    required AbsenceReason reason,
    String? excuse,
  }) async {
    if (state.session == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Buscar worker en la lista
      final worker = state.session!.workers.firstWhere(
        (w) => w.id == workerId,
      );

      // Registrar ausencia en el servidor
      await _apiService.markWorkerAbsent(
        workerId: workerId,
        workdayId: state.session!.workday!.id!,
        reason: reason,
        excuse: excuse,
      );

      // Crear worker ausente
      final absentWorker = WorkerScanModel.absent(
        worker: worker,
        reason: reason,
        excuse: excuse,
      );

      // Actualizar sesión
      final updatedSession = state.session!.addAbsentWorker(absentWorker);

      state = state.copyWith(
        session: updatedSession,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Finalizar sesión de clock-in
  Future<void> finishSession() async {
    if (state.session == null || !state.session!.canFinishSession) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _ref.read(userProvider).user;
      if (user == null) throw Exception('User not found');

      // Obtener ubicación actual
      final location = await _locationService.getCurrentLocation();
      final locationString = location != null 
          ? '${location.latitude} ${location.longitude}'
          : 'N/A';

      // Finalizar workday en el servidor
      await _apiService.finishClockIn(
        workdayId: state.session!.workday!.id!,
        location: locationString,
        finishedByUserId: user.id,
      );

      // Refrescar workday desde el servidor para obtener el estado actualizado
      final updatedWorkday = await _apiService.getCurrentWorkday(user.contract);

      // Actualizar sesión con el workday actualizado
      final updatedSession = state.session!.copyWith(
        workday: updatedWorkday,
        status: ClockinStatus.finished,
      );

      state = state.copyWith(
        session: updatedSession,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Refrescar datos de la sesión
  Future<void> refreshSession() async {
    if (state.session?.contractId == null) return;
    
    await initializeSession(int.parse(state.session!.contractId!));
  }

  // Validar estado del workday desde el servidor
  Future<bool> validateWorkdayStatus() async {
    if (state.session?.workday?.id == null) return false;
    
    try {
      return await _apiService.validateWorkdayStatus(state.session!.workday!.id!);
    } catch (e) {
      print('Error validating workday status: $e');
      return false;
    }
  }

  // Actualizar hora de inicio del workday
  Future<void> updateInitTime(DateTime newTime) async {
    if (state.session?.workday?.id == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedWorkday = await _apiService.updateWorkdayInitTime(
        workdayId: state.session!.workday!.id!,
        newTime: newTime,
      );
      
      final updatedSession = state.session!.copyWith(
        workday: updatedWorkday,
      );
      
      state = state.copyWith(
        session: updatedSession,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Hacer clock-in del supervisor
  Future<void> doSupervisorClockin() async {
    if (state.session?.workday?.id == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = _ref.read(userProvider).user;
      if (user == null) throw Exception('User not found');
      
      // Obtener ubicación actual
      final location = await _locationService.getCurrentLocation();
      final locationString = location != null 
          ? '${location.latitude} ${location.longitude}'
          : 'N/A';
      
      await _apiService.doSupervisorClockin(
        workdayId: state.session!.workday!.id!,
        userId: user.id,
        location: locationString,
        temperature: '90', // Temperatura hardcodeada
      );
      
      // Actualizar estado para reflejar que supervisor ya hizo clock-in
      final updatedSession = state.session!.copyWith(
        supervisorHasClockin: true,
      );
      
      state = state.copyWith(
        session: updatedSession,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Verificar si el supervisor ya hizo su clock-in
  Future<bool> checkSupervisorClockin() async {
    if (state.session?.workday?.id == null) return false;
    
    try {
      final user = _ref.read(userProvider).user;
      if (user == null) return false;
      
      // Obtener lista de workers escaneados
      final clockedInWorkers = await _apiService.getClockedInWorkers(
        state.session!.workday!.id!,
      );
      
      // Verificar si el supervisor está en la lista
      return clockedInWorkers.any((w) => w.workerId == user.id);
    } catch (e) {
      print('Error checking supervisor clock-in: $e');
      return false;
    }
  }

  // Refrescar listas de workers (escaneados, ausentes)
  Future<void> refreshWorkerLists() async {
    if (state.session?.workday?.id == null) return;
    
    try {
      // Obtener workers escaneados del servidor
      final clockedInWorkers = await _apiService.getClockedInWorkers(
        state.session!.workday!.id!,
      );
      
      print('Workers escaneados obtenidos: ${clockedInWorkers.length}');
      
      // Convertir WorkerClockinModel a WorkerScanModel
      final scannedWorkers = clockedInWorkers.map((w) {
        return WorkerScanModel(
          id: w.workerId,
          firstName: w.firstName,
          lastName: w.lastName,
          email: '', // Email no disponible en WorkerClockinModel
          btnId: w.btnId,
          status: WorkerStatus.scanned,
          scannedAt: w.clockTime,
        );
      }).toList();
      
      // Obtener workers ausentes
      final absentWorkers = await _apiService.getAbsentWorkers(
        state.session!.workday!.id!,
      );
      
      // Actualizar sesión con las listas actualizadas
      final updatedSession = state.session!.copyWith(
        scannedWorkers: scannedWorkers,
        absentWorkers: absentWorkers,
      );
      
      state = state.copyWith(session: updatedSession);
      
    } catch (e) {
      print('Error refreshing worker lists: $e');
    }
  }

  // Registrar clock-in del worker (worker ya verificado en scanner)
  Future<Map<String, dynamic>> registerWorkerClockin({
    required int workerId,
    required String workerName,
    required String location,
  }) async {
    try {
      final session = state.session;
      if (session == null || session.workday == null) {
        return {
          'success': false,
          'error': 'No active workday',
        };
      }

      // CRÍTICO: Obtener default_init actualizado de BD local
      // NO usar session.workday.defaultEntryTime (hora inicial)
      final workdayOn = await DatabaseHelper.getWorkdayOn();
      final defaultEntryTime = workdayOn != null && workdayOn['default_init'] != null
          ? workdayOn['default_init'] as String
          : DateTime.now().toIso8601String();
      
      print('📋 Registering worker with defaultEntryTime: $defaultEntryTime');
      print('   (NOT using session.workday.defaultEntryTime: ${session.workday!.defaultEntryTime})');
      
      // Registrar clock-in del worker directamente (sin verificar de nuevo)
      final registered = await _apiService.registerWorkerClockin(
        workdayId: session.workday!.id!,
        workerId: workerId,
        location: location,
        defaultEntryTime: defaultEntryTime,  // Usar hora actualizada de BD local
      );

      if (!registered) {
        return {
          'success': false,
          'error': 'Failed to register worker clock-in',
        };
      }

      // Actualizar estado local sin llamar al API (optimización de velocidad)
      // El dashboard se actualizará cuando vuelva a él
      
      return {
        'success': true,
        'workerName': workerName,
        'workerId': workerId,
      };
    } catch (e) {
      print('Error registering worker clock-in: $e');
      return {
        'success': false,
        'error': 'Error processing clock-in: $e',
      };
    }
  }

  // Validar si debe actualizar hora antes de escanear
  Future<ValidationResult> validateBeforeScan() async {
    final user = _ref.read(userProvider).user;
    if (user == null) {
      throw Exception('User not found');
    }

    return await ClockInValidationService.validateScanTiming(
      currentSupervisorId: user.btnId,
      currentSupervisorName: '${user.firstName} ${user.lastName}',
    );
  }

  // Crear nueva sesión de supervisor (cuando actualiza hora)
  Future<int> createNewSession({
    required DateTime sessionStartTime,
    bool? isAutoMode,
  }) async {
    if (state.session?.workday?.id == null) {
      throw Exception('No active workday');
    }

    final user = _ref.read(userProvider).user;
    if (user == null) {
      throw Exception('User not found');
    }

    // CRÍTICO: Actualizar default_init en BD local con la nueva hora
    await DatabaseHelper.updateDefaultInit(sessionStartTime);
    print('✅ Updated default_init to: $sessionStartTime (hora actualizada por usuario)');
    
    // Al actualizar hora, usar la hora seleccionada por usuario para ult_clock
    return await ClockInValidationService.getOrCreateSession(
      workdayId: state.session!.workday!.id!,
      supervisorId: user.btnId,
      supervisorName: '${user.firstName} ${user.lastName}',
      sessionStartTime: sessionStartTime,
      isAutoMode: isAutoMode ?? state.session!.isAutomaticMode,
      useCurrentTimeForUltClock: false,  // Usar sessionStartTime (hora seleccionada)
    );
  }

  // Limpiar datos de BD local al finalizar reporte
  Future<void> clearLocalData() async {
    try {
      await DatabaseHelper.clearWorkdayData();
      print('✅ Local workday data cleared');
    } catch (e) {
      print('❌ Error clearing local data: $e');
    }
  }

  // Limpiar error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Verificar si el supervisor ha hecho su propio clock-in
  Future<bool> checkSupervisorHasClockedIn() async {
    try {
      final user = _ref.read(userProvider).user;
      if (user == null) return false;

      final session = state.session;
      if (session == null) return false;

      // Verificar en la lista de workers escaneados
      final supervisorBtnId = user.btnId;
      final hasScanned = session.scannedWorkers.any(
        (worker) => worker.btnId == supervisorBtnId,
      );

      print('🔍 Supervisor clock-in check:');
      print('   Supervisor btn_id: $supervisorBtnId');
      print('   Has clocked in: $hasScanned');
      
      return hasScanned;
    } catch (e) {
      print('Error checking supervisor clock-in: $e');
      return false;
    }
  }

  // Finalizar proceso de clock-in
  Future<Map<String, dynamic>> finishClockin() async {
    try {
      final session = state.session;
      if (session == null || session.workday == null) {
        return {
          'success': false,
          'error': 'No active workday found',
        };
      }

      final workdayId = session.workday!.id;
      if (workdayId == null) {
        return {
          'success': false,
          'error': 'Invalid workday ID',
        };
      }

      // Obtener ubicación actual (usar coordenadas por defecto si falla)
      final location = await _locationService.getCurrentLocation();
      final locationString = location != null 
          ? '${location.latitude} ${location.longitude}' 
          : '18.4655 -66.1057'; // San Juan, PR por defecto

      // Obtener ID del supervisor desde el userProvider
      final userState = _ref.read(userProvider);
      final supervisorId = userState.user?.id ?? 0;
      if (supervisorId == 0) {
        return {
          'success': false,
          'error': 'Invalid supervisor ID',
        };
      }

      // Llamar al API para finalizar
      final success = await _apiService.finishClockin(
        workdayId: workdayId,
        supervisorId: supervisorId,
        location: locationString,
      );

      if (success) {
        // Actualizar estado local
        final updatedWorkday = session.workday!.copyWith(
          clockInEnd: DateTime.now().toIso8601String(),
        );
        
        final updatedSession = session.copyWith(
          workday: updatedWorkday,
          status: ClockinStatus.finished,
        );

        state = state.copyWith(session: updatedSession);

        return {
          'success': true,
          'message': 'Clock-in process finished successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to finish clock-in process',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error finishing clock-in: $e',
      };
    }
  }

  // Resetear sesión
  void resetSession() {
    state = const ClockinState();
  }
}

// Providers
final clockinApiServiceProvider = Provider<ClockinApiService>((ref) {
  return ClockinApiService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final clockinProvider = StateNotifierProvider<ClockinNotifier, ClockinState>((ref) {
  final apiService = ref.read(clockinApiServiceProvider);
  final locationService = ref.read(locationServiceProvider);
  
  return ClockinNotifier(apiService, locationService, ref);
});

// Providers auxiliares para acceso fácil
final currentSessionProvider = Provider<ClockinSessionModel?>((ref) {
  return ref.watch(clockinProvider).session;
});

final clockinStatusProvider = Provider<ClockinStatus>((ref) {
  return ref.watch(clockinProvider).session?.status ?? ClockinStatus.notStarted;
});

final pendingWorkersProvider = Provider<List<WorkerScanModel>>((ref) {
  return ref.watch(clockinProvider).session?.pendingWorkers ?? [];
});

final scannedWorkersProvider = Provider<List<WorkerScanModel>>((ref) {
  return ref.watch(clockinProvider).session?.scannedWorkers ?? [];
});

final absentWorkersProvider = Provider<List<WorkerScanModel>>((ref) {
  return ref.watch(clockinProvider).session?.absentWorkers ?? [];
});

final clockinProgressProvider = Provider<double>((ref) {
  return ref.watch(clockinProvider).session?.completionPercentage ?? 0.0;
});
