import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_storage.dart';
import '../models/user_model.dart';

/// Estado del usuario
class UserState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const UserState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider del usuario
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(const UserState()) {
    _loadUserFromStorage();
  }

  final _storage = LocalStorage.instance;

  /// Cargar usuario desde el storage local
  Future<void> _loadUserFromStorage() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final userData = _storage.getString('user_data');
      if (userData != null && userData.isNotEmpty) {
        // Deserializar el JSON del usuario
        final Map<String, dynamic> userJson = json.decode(userData);
        final user = UserModel.fromJson(userJson);
        state = state.copyWith(user: user, isLoading: false);
        return;
      }
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: 'Error loading user data: $e');
    }
  }

  /// Establecer usuario después del login
  Future<void> setUser(UserModel user) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Guardar en storage local
      await _saveUserToStorage(user);

      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error saving user data: $e',
      );
    }
  }

  /// Guardar usuario en storage local
  Future<void> _saveUserToStorage(UserModel user) async {
    await _storage.saveString('user_data', json.encode(user.toJson()));
    await _storage.saveAuthToken(user.token);
    await _storage.saveUserId(user.userId);
    await _storage.saveUserEmail(user.email);
    await _storage.saveUserRole(user.role);
    await _storage.saveString('user_btn_id', user.btnId);
    await _storage.saveString('user_full_name', user.fullName);
    await _storage.saveString('user_profile_image', user.profileImage ?? '');
    await _storage.saveInt('user_contract', user.contract);
    await _storage.saveString('user_location_list', user.locationList.toString());
  }

  /// Actualizar información del usuario
  Future<void> updateUser(UserModel updatedUser) async {
    if (state.user != null) {
      await setUser(updatedUser);
    }
  }

  /// Limpiar datos del usuario (logout)
  Future<void> clearUser() async {
    await _storage.clearSession();
    await _storage.prefs.remove('user_data');
    await _storage.prefs.remove('user_btn_id');
    await _storage.prefs.remove('user_full_name');
    await _storage.prefs.remove('user_profile_image');
    await _storage.prefs.remove('user_contract');
    await _storage.prefs.remove('user_location_list');
    
    state = const UserState();
  }

  /// Verificar si el usuario es business
  bool get isBusiness {
    return state.user?.isBusiness ?? false;
  }

  /// Obtener el rol del usuario
  String get userRole {
    return state.user?.role ?? 'worker';
  }

  /// Obtener el btn_id del usuario
  String get btnId {
    return state.user?.btnId ?? '';
  }

  /// Obtener el nombre completo del usuario
  String get fullName {
    return state.user?.fullName ?? '';
  }

  /// Obtener la imagen de perfil del usuario
  String? get profileImage {
    return state.user?.profileImage;
  }

  /// Obtener el contrato activo del usuario
  int get activeContract {
    return state.user?.contract ?? 0;
  }

  /// Verificar si tiene ubicaciones (para determinar si es business)
  bool get hasLocations {
    return state.user?.locationList.isNotEmpty ?? false;
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
