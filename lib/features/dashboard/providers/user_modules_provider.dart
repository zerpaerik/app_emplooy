import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client.dart';
import '../../../core/storage/local_storage.dart';
import '../models/user_modules.dart';

/// Estado de los módulos del usuario
class UserModulesState {
  final bool isLoading;
  final UserModules? modules;
  final String? error;
  final bool hasLoadedFromServer;

  const UserModulesState({
    this.isLoading = false,
    this.modules,
    this.error,
    this.hasLoadedFromServer = false,
  });

  UserModulesState copyWith({
    bool? isLoading,
    UserModules? modules,
    String? error,
    bool? hasLoadedFromServer,
  }) {
    return UserModulesState(
      isLoading: isLoading ?? this.isLoading,
      modules: modules ?? this.modules,
      error: error,
      hasLoadedFromServer: hasLoadedFromServer ?? this.hasLoadedFromServer,
    );
  }
}

/// Provider de módulos del usuario
final userModulesProvider = StateNotifierProvider<UserModulesNotifier, UserModulesState>((ref) {
  return UserModulesNotifier();
});

class UserModulesNotifier extends StateNotifier<UserModulesState> {
  UserModulesNotifier() : super(const UserModulesState()) {
    _initializeModules();
  }

  final _httpClient = HttpClient.instance;
  final _storage = LocalStorage.instance;

  /// Inicializar módulos con valores por defecto
  void _initializeModules() {
    // Cargar módulos por defecto basados en el rol almacenado
    final role = _storage.getUserRole() ?? 'worker';
    final defaultModules = DefaultModules.forRole(role);
    
    state = state.copyWith(
      modules: defaultModules,
    );
  }

  /// Obtener módulos del usuario desde el servidor
  Future<void> fetchUserModules() async {
    // Evitar cargas múltiples
    if (state.isLoading || state.hasLoadedFromServer) {
      return;
    }
    
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _httpClient.get(
        '/api/v-1/contract/modules-worker',
        requiresAuth: true,
      );

      if (_httpClient.isSuccessful(response)) {
        final data = _httpClient.parseResponse(response);
        if (data != null) {
          final modules = UserModules.fromJson(data);
          
          // Guardar en storage local
          await _saveModulesToStorage(modules);
          
          state = state.copyWith(
            isLoading: false,
            modules: modules,
            hasLoadedFromServer: true,
          );
        }
      } else {
        // Si falla, mantener módulos por defecto
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load user modules from server',
          hasLoadedFromServer: true,
        );
      }
    } catch (e) {
      // En caso de error, mantener módulos por defecto
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
        hasLoadedFromServer: true,
      );
    }
  }

  /// Guardar módulos en storage local
  Future<void> _saveModulesToStorage(UserModules modules) async {
    await _storage.saveString('user_modules', 
        '${modules.clockInModule},${modules.clockOutModule},${modules.expensesModule},${modules.warningsModule},${modules.workdayReportsModule}');
    await _storage.saveString('user_role_updated', modules.role);
  }

  /// Cargar módulos desde storage local
  Future<UserModules?> _loadModulesFromStorage() async {
    try {
      final modulesString = _storage.getString('user_modules');
      final role = _storage.getString('user_role_updated');
      
      if (modulesString != null && role != null) {
        final parts = modulesString.split(',');
        if (parts.length == 5) {
          return UserModules(
            clockInModule: parts[0] == 'true',
            clockOutModule: parts[1] == 'true',
            expensesModule: parts[2] == 'true',
            warningsModule: parts[3] == 'true',
            workdayReportsModule: parts[4] == 'true',
            role: role,
          );
        }
      }
    } catch (e) {
      print('Error loading modules from storage: $e');
    }
    return null;
  }

  /// Refrescar módulos del usuario (forzar recarga)
  Future<void> refreshModules() async {
    state = state.copyWith(hasLoadedFromServer: false);
    await fetchUserModules();
  }

  /// Verificar si el usuario tiene acceso a un módulo específico
  bool hasModuleAccess(String moduleName) {
    final modules = state.modules;
    if (modules == null) return false;

    switch (moduleName) {
      case 'clock_in':
        return modules.clockInModule;
      case 'clock_out':
        return modules.clockOutModule;
      case 'expenses':
        return modules.expensesModule;
      case 'warnings':
        return modules.warningsModule;
      case 'workday_reports':
        return modules.workdayReportsModule;
      default:
        return false;
    }
  }

  /// Verificar si el usuario es supervisor o lead
  bool isSupervisorOrLead() {
    final modules = state.modules;
    if (modules == null) return false;
    return modules.role == 'supervisor' || modules.role == 'is_lead';
  }

  /// Verificar si el usuario es business
  bool isBusiness() {
    final modules = state.modules;
    if (modules == null) return false;
    return modules.role == 'business' || modules.role == 'customer';
  }

  /// Obtener el rol del usuario
  String getUserRole() {
    return state.modules?.role ?? 'worker';
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
