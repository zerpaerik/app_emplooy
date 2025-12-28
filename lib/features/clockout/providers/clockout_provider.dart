import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clockout_session_model.dart';
import '../models/worker_clockout_model.dart';
import '../../clockin/models/workday_model.dart';
import '../services/clockout_api_service.dart';
import '../services/clockout_validation_service.dart';
import '../../clockin/services/location_service.dart';
import '../../clockin/services/clockin_api_service.dart';
import '../../clockin/providers/clockin_provider.dart' show locationServiceProvider;
import '../../user/providers/user_provider.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/local_database.dart';

// Estado del provider de clock-out
class ClockoutState {
  final ClockoutSessionModel? session;
  final bool isLoading;
  final String? error;

  const ClockoutState({
    this.session,
    this.isLoading = false,
    this.error,
  });

  ClockoutState copyWith({
    ClockoutSessionModel? session,
    bool? isLoading,
    String? error,
  }) {
    return ClockoutState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier para manejar el estado de clock-out
class ClockoutNotifier extends StateNotifier<ClockoutState> {
  final ClockoutApiService _apiService;
  final ClockinApiService _clockinApiService;
  final LocationService _locationService;
  final Ref _ref;

  ClockoutNotifier(this._apiService, this._clockinApiService, this._locationService, this._ref) 
      : super(const ClockoutState()) {
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      await LocalDatabase.instance.database;
      print('✅ Local database initialized for clock-out');
    } catch (e) {
      print('❌ Error initializing database: $e');
    }
  }

  // Inicializar sesión de clock-out
  Future<void> initializeSession(int contractId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Obtener workday actual del servidor
      WorkdayModel? workday;
      String? contractName;
      String? companyName;
      
      try {
        final workdayResult = await _apiService.getCurrentWorkday(contractId);
        
        if (workdayResult['success'] == true) {
          final workdayData = workdayResult['data'];
          workday = WorkdayModel.fromJson(workdayData);
          contractName = workdayData['contract_name'];
          companyName = workdayData['company_name'];
          print('Workday obtenido: ${workday.id}, clock_in_end: ${workday.clockInEnd}');
        } else {
          print('No workday found (404), will show no workday message');
          workday = null;
        }
      } catch (e) {
        print('No workday found: $e');
        workday = null;
      }

      // Si no hay workday, crear sesión indicando que no hay workday
      if (workday == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'NO_WORKDAY',
          session: ClockoutSessionModel(
            contractId: contractId.toString(),
            workday: null,
            status: ClockoutStatus.notStarted,
          ),
        );
        return;
      }

      // Validar que el clock-in esté finalizado
      if (workday.clockInEnd == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'CLOCK_IN_NOT_FINISHED',
          session: ClockoutSessionModel(
            contractId: contractId.toString(),
            workday: workday,
            status: ClockoutStatus.notStarted,
          ),
        );
        return;
      }

      // Determinar el estado según el workday
      ClockoutStatus status;
      if (workday.clockOutEnd != null) {
        status = ClockoutStatus.finished;
      } else if (workday.clockOutStart != null) {
        status = ClockoutStatus.active;
      } else {
        status = ClockoutStatus.setup;
      }

      final session = ClockoutSessionModel(
        contractId: contractId.toString(),
        contractName: contractName,
        companyName: companyName,
        workday: workday,
        status: status,
      );

      state = state.copyWith(
        session: session,
        isLoading: false,
      );

      // Si está activo, cargar listas de workers
      if (status == ClockoutStatus.active) {
        await refreshWorkerLists();
      }
    } catch (e) {
      print('Error initializing clockout session: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error initializing session: $e',
      );
    }
  }

  // Iniciar proceso de clock-out
  Future<Map<String, dynamic>> startClockoutProcess({
    required DateTime exitDate,
    required DateTime exitTime,
    required bool automaticClockout,
  }) async {
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

      // Combinar fecha y hora
      final clockOutStart = DateTime(
        exitDate.year,
        exitDate.month,
        exitDate.day,
        exitTime.hour,
        exitTime.minute,
      );

      // Obtener ubicación actual (usar coordenadas por defecto si falla)
      final location = await _locationService.getCurrentLocation();
      final locationString = location != null 
          ? '${location.latitude} ${location.longitude}' 
          : '18.4655 -66.1057'; // San Juan, PR por defecto

      final success = await _apiService.startClockoutProcess(
        workdayId: workdayId,
        clockOutStart: clockOutStart.toIso8601String(),
        defaultExitTime: clockOutStart.toIso8601String(),
        supervisorClock: automaticClockout,
        location: locationString,
      );

      if (success) {
        // Guardar default_exit (hora seleccionada por usuario) en BD local
        await DatabaseHelper.updateDefaultExit(clockOutStart);
        print('✅ Saved default_exit: $clockOutStart (hora seleccionada por usuario)');
        
        // Crear sesión inicial en BD local para validación multi-supervisor
        final user = _ref.read(userProvider).user;
        if (user != null) {
          try {
            await ClockOutValidationService.getOrCreateSession(
              workdayId: workdayId,
              supervisorId: user.btnId,
              supervisorName: '${user.firstName} ${user.lastName}',
              sessionStartTime: clockOutStart,
              isAutoMode: automaticClockout,
            );
            print('✅ Initial clock-out session created in local DB');
            print('✅ Created session with ultClockOut = DateTime.now() (hora actual del momento)');
          } catch (e) {
            print('⚠️ Error creating initial session in local DB: $e');
          }
        }
        
        // Actualizar estado local
        final updatedWorkday = session.workday!.copyWith(
          clockOutStart: clockOutStart.toIso8601String(),
          defaultExitTime: clockOutStart.toIso8601String(),
        );

        final updatedSession = session.copyWith(
          workday: updatedWorkday,
          status: ClockoutStatus.active,
        );

        state = state.copyWith(session: updatedSession);

        return {
          'success': true,
          'message': 'Clock-out process started successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to start clock-out process',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error starting clock-out: $e',
      };
    }
  }

  // Refrescar listas de workers
  Future<void> refreshWorkerLists() async {
    try {
      final session = state.session;
      if (session == null || session.workday?.id == null) return;

      final workdayId = session.workday!.id!;

      // Obtener workers con clock-out y pendientes en paralelo
      final results = await Future.wait([
        _apiService.getClockedOutWorkers(workdayId),
        _apiService.getPendingWorkers(workdayId),
      ]);

      final clockedOutData = results[0];
      final pendingData = results[1];

      // Convertir a modelos
      final clockedOutWorkers = clockedOutData
          .map((w) => WorkerClockoutModel.fromJson(w))
          .toList();

      final pendingWorkers = pendingData
          .map((w) => WorkerClockoutModel.fromJson(w))
          .toList();

      final totalWorkers = clockedOutWorkers.length + pendingWorkers.length;

      final updatedSession = session.copyWith(
        clockedOutWorkers: clockedOutWorkers,
        pendingWorkers: pendingWorkers,
        totalWorkers: totalWorkers,
      );

      state = state.copyWith(session: updatedSession);
    } catch (e) {
      print('Error refreshing worker lists: $e');
    }
  }

  // Escanear QR de worker para clock-out
  Future<Map<String, dynamic>> scanWorkerQR({
    required String identification,
    required String location,
  }) async {
    try {
      final session = state.session;
      if (session == null || session.workday == null) {
        return {
          'success': false,
          'error': 'No active workday found',
        };
      }

      final contractId = int.tryParse(session.contractId ?? '0') ?? 0;
      if (contractId == 0) {
        return {
          'success': false,
          'error': 'Invalid contract ID',
        };
      }

      // Verificar worker con API
      final verifyResult = await _apiService.verifyWorkerQR(
        identification: identification,
        contractId: contractId,
      );

      if (verifyResult['success'] != true) {
        return verifyResult;
      }

      // Worker válido, retornar datos para mostrar en detail page
      return {
        'success': true,
        'data': verifyResult['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error processing QR: $e',
      };
    }
  }

  // Registrar clock-out de worker
  Future<Map<String, dynamic>> registerWorkerClockout({
    required int workerId,
    required String location,
  }) async {
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
          'error': 'Invalid workday data',
        };
      }

      // CRÍTICO: Obtener default_exit actualizado de BD local
      // NO usar session.workday.defaultExitTime (hora inicial)
      final workdayOn = await DatabaseHelper.getWorkdayOn();
      final defaultExitTime = workdayOn != null && workdayOn['default_exit'] != null
          ? workdayOn['default_exit'] as String
          : DateTime.now().toIso8601String();
      
      print('📋 Registering worker with defaultExitTime: $defaultExitTime');
      print('   (NOT using session.workday.defaultExitTime: ${session.workday!.defaultExitTime})');

      final success = await _apiService.registerWorkerClockout(
        workdayId: workdayId,
        workerId: workerId,
        location: location,
        defaultExitTime: defaultExitTime,  // Usar hora actualizada de BD local
      );

      if (success) {
        // Registrar en BD local para validación multi-supervisor
        final user = _ref.read(userProvider).user;
        if (user != null) {
          try {
            // Obtener o crear sesión actual
            final currentSessionMap = await DatabaseHelper.getCurrentSession('OUT');
            int sessionId;
            
            if (currentSessionMap == null) {
              // Primera vez - crear sesión inicial
              sessionId = await ClockOutValidationService.getOrCreateSession(
                workdayId: workdayId,
                supervisorId: user.btnId,
                supervisorName: '${user.firstName} ${user.lastName}',
                sessionStartTime: DateTime.now(),
                isAutoMode: false,
              );
            } else {
              sessionId = currentSessionMap['id'] as int;
            }
            
            // Registrar worker en la sesión
            await recordWorkerInSession(
              workerId: workerId,
              workerBtnId: workerId.toString(),
              workerName: 'Worker $workerId',
              location: location,
            );
          } catch (e) {
            print('⚠️ Error registering in local DB: $e');
          }
        }
        
        return {
          'success': true,
          'message': 'Worker clock-out registered successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to register worker clock-out',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error registering clock-out: $e',
      };
    }
  }

  // Verificar si el supervisor ha hecho su propio clock-out
  Future<bool> checkSupervisorHasClockedOut() async {
    try {
      final user = _ref.read(userProvider).user;
      if (user == null) return false;

      final session = state.session;
      if (session == null) return false;

      // Verificar en la lista de workers con clock-out
      final supervisorBtnId = user.btnId;
      final hasScanned = session.clockedOutWorkers.any(
        (worker) => worker.btnId == supervisorBtnId,
      );

      print('🔍 Supervisor clock-out check:');
      print('   Supervisor btn_id: $supervisorBtnId');
      print('   Has clocked out: $hasScanned');
      
      return hasScanned;
    } catch (e) {
      print('Error checking supervisor clock-out: $e');
      return false;
    }
  }

  // Finalizar proceso de clock-out
  Future<Map<String, dynamic>> finishClockout() async {
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

      // Obtener ID del supervisor
      final userState = _ref.read(userProvider);
      final supervisorId = userState.user?.id ?? 0;
      if (supervisorId == 0) {
        return {
          'success': false,
          'error': 'Invalid supervisor ID',
        };
      }

      // Llamar al API para finalizar
      final success = await _apiService.finishClockout(
        workdayId: workdayId,
        supervisorId: supervisorId,
        location: locationString,
      );

      if (success) {
        // Refrescar workday desde el servidor para obtener el estado actualizado
        final userState = _ref.read(userProvider);
        final contractId = userState.user?.contract ?? 0;
        
        WorkdayModel? updatedWorkday;
        if (contractId > 0) {
          try {
            updatedWorkday = await _clockinApiService.getCurrentWorkday(contractId);
          } catch (e) {
            print('Error refreshing workday: $e');
            // Si falla, usar el workday local actualizado
            updatedWorkday = session.workday!.copyWith(
              clockOutEnd: DateTime.now().toIso8601String(),
            );
          }
        } else {
          updatedWorkday = session.workday!.copyWith(
            clockOutEnd: DateTime.now().toIso8601String(),
          );
        }
        
        final updatedSession = session.copyWith(
          workday: updatedWorkday,
          status: ClockoutStatus.finished,
        );

        state = state.copyWith(session: updatedSession);

        return {
          'success': true,
          'message': 'Clock-out process finished successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to finish clock-out process',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error finishing clock-out: $e',
      };
    }
  }

  // Validar si debe actualizar hora antes de escanear
  Future<ClockOutValidationResult> validateBeforeScan() async {
    final user = _ref.read(userProvider).user;
    if (user == null) {
      throw Exception('User not found');
    }

    return await ClockOutValidationService.validateScanTiming(
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

    // CRÍTICO: Actualizar default_exit en BD local con la nueva hora
    await DatabaseHelper.updateDefaultExit(sessionStartTime);
    print('✅ Updated default_exit to: $sessionStartTime (hora actualizada por usuario)');
    
    // Al actualizar hora, usar la hora seleccionada por usuario para ultClockOut
    return await ClockOutValidationService.getOrCreateSession(
      workdayId: state.session!.workday!.id!,
      supervisorId: user.btnId,
      supervisorName: '${user.firstName} ${user.lastName}',
      sessionStartTime: sessionStartTime,
      isAutoMode: isAutoMode ?? false,
      useCurrentTimeForUltClock: false,  // Usar sessionStartTime (hora seleccionada)
    );
  }

  // Registrar worker en sesión de BD local
  Future<void> recordWorkerInSession({
    required int workerId,
    required String workerBtnId,
    required String workerName,
    required String location,
  }) async {
    final currentSessionMap = await DatabaseHelper.getCurrentSession('OUT');
    if (currentSessionMap == null) {
      throw Exception('No active session found');
    }

    final sessionId = currentSessionMap['id'] as int;
    
    // FIX 2: Usar hora ACTUAL del escaneo, no la hora de inicio de sesión
    final actualClockTime = DateTime.now();
    
    // Obtener supervisor ID del usuario actual
    final user = _ref.read(userProvider).user;
    if (user == null) {
      throw Exception('User not found');
    }

    await ClockOutValidationService.recordWorkerScan(
      sessionId: sessionId,
      workerId: workerId,
      workerBtnId: workerBtnId,
      workerName: workerName,
      clockTime: actualClockTime,
      location: location,
      supervisorId: user.btnId,
    );

    print('✅ Worker $workerName clocked out in session $sessionId');
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

  // Resetear sesión
  void resetSession() {
    state = const ClockoutState();
  }
}

// Providers
final clockoutApiServiceProvider = Provider<ClockoutApiService>((ref) {
  return ClockoutApiService();
});

final clockinApiServiceProvider = Provider<ClockinApiService>((ref) {
  return ClockinApiService();
});

final clockoutProvider = StateNotifierProvider<ClockoutNotifier, ClockoutState>((ref) {
  final apiService = ref.read(clockoutApiServiceProvider);
  final clockinApiService = ref.read(clockinApiServiceProvider);
  final locationService = ref.read(locationServiceProvider);
  
  return ClockoutNotifier(apiService, clockinApiService, locationService, ref);
});

// Providers auxiliares
final currentClockoutSessionProvider = Provider<ClockoutSessionModel?>((ref) {
  return ref.watch(clockoutProvider).session;
});

final clockoutStatusProvider = Provider<ClockoutStatus>((ref) {
  return ref.watch(clockoutProvider).session?.status ?? ClockoutStatus.notStarted;
});
