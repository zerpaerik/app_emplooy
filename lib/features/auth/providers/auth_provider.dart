import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/http_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../user/models/user_model.dart';
import '../../user/providers/user_provider.dart';

/// Estado de autenticación
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final Map<String, dynamic>? user;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      user: user ?? this.user,
    );
  }
}

/// Provider de autenticación
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState()) {
    _checkAuthStatus();
  }

  final Ref _ref;
  final _httpClient = HttpClient.instance;
  final _storage = LocalStorage.instance;

  /// Verificar estado de autenticación al iniciar
  Future<void> _checkAuthStatus() async {
    final isLoggedIn = _storage.isLoggedIn();
    final token = await _storage.getAuthToken();

    if (isLoggedIn && token != null) {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  /// Método de login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _httpClient.post(
        '/api/v-2/auth/login',
        body: {
          'username': email,
          'password': password,
          'fcm_token': 'PATCH',
        },
      );

      if (_httpClient.isSuccessful(response)) {
        final data = _httpClient.parseResponse(response);
        if (data != null) {
          // Crear modelo de usuario completo
          final user = UserModel.fromJson(data);
          
          // Guardar usuario completo usando UserProvider
          await _ref.read(userProvider.notifier).setUser(user);
          
          // Marcar como logueado
          await _storage.setLoggedIn(true);

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: {
              'id': data['user_id'],
              'email': data['email'],
              'firstName': data['first_name'] ?? '',
              'lastName': data['last_name'] ?? '',
              'role': data['role'] ?? 'worker',
            },
          );
          return true;
        }
      }

      // Error en la respuesta
      final errorData = _httpClient.parseResponse(response);
      final errorMessage = errorData?['message'] ?? 'Login failed';
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error. Please try again.',
      );
      return false;
    }
  }

  /// Método de registro
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _httpClient.post(
        AppConstants.apiRegisterUser,
        body: {
          'email': email.toLowerCase(),
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'role': 'worker',
        },
      );

      if (_httpClient.isSuccessful(response)) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        final errorData = _httpClient.parseResponse(response);
        String errorMessage = 'Registration failed. Please try again.';

        if (errorData != null) {
          errorMessage = errorData['message'] ?? errorMessage;
        }

        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error. Please check your connection.',
      );
      return false;
    }
  }

  /// Verificar email para recuperación de contraseña
  Future<Map<String, dynamic>> verifyEmail(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _httpClient.get(
        '/api/v-1/auth/verify_email/${email.toLowerCase()}/',
      );

      if (_httpClient.isSuccessful(response)) {
        final data = _httpClient.parseResponse(response);
        state = state.copyWith(isLoading: false);
        return {
          'success': true,
          'user_id': data, // El endpoint devuelve el user_id directamente
        };
      }

      final errorData = _httpClient.parseResponse(response);
      final errorMessage = errorData?['message'] ?? 'Email not found';
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error. Please try again.',
      );
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  /// Verificar código de recuperación
  Future<bool> verifyCode(String code, int userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _httpClient.get(
        '/api/v-1/auth/verify_code/$userId/$code/',
      );

      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false);
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Invalid verification code',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error. Please try again.',
      );
      return false;
    }
  }

  /// Cambiar contraseña
  Future<bool> changePassword(String newPassword, int userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _httpClient.patch(
        '/api/v-1/auth/change_password/$userId/',
        body: {
          'password1': newPassword,
          'password2': newPassword,
        },
      );

      if (_httpClient.isSuccessful(response)) {
        state = state.copyWith(isLoading: false);
        return true;
      }

      final errorData = _httpClient.parseResponse(response);
      final errorMessage = errorData?['message'] ?? 'Failed to change password';
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error. Please try again.',
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      // Intentar hacer logout en el servidor
      await _httpClient.post(
        AppConstants.apiAuthLogout,
        body: {},
        requiresAuth: true,
      );
    } catch (e) {
      // Continuar con logout local aunque falle el servidor
    }

    // Limpiar datos locales
    await _storage.clearSession();
    
    // Limpiar datos del usuario
    await _ref.read(userProvider.notifier).clearUser();

    state = const AuthState();
  }

  /// Validar si el token actual es válido
  Future<bool> validateToken() async {
    try {
      final token = await _storage.getAuthToken();
      if (token == null) return false;

      // Intentar obtener datos del usuario para validar el token
      final response = await _httpClient.get(
        '/api/v-1/user/me/',
        requiresAuth: true,
      );

      return _httpClient.isSuccessful(response);
    } catch (e) {
      return false;
    }
  }

  /// Limpiar TODOS los datos de la app (para desinstalación/reinstalación)
  Future<void> clearAllData() async {
    try {
      // Limpiar todos los datos de SharedPreferences
      await _storage.clearAll();
      
      // Limpiar datos del usuario
      await _ref.read(userProvider.notifier).clearUser();
      
      // Resetear estado de autenticación
      state = const AuthState();
    } catch (e) {
      print('Error clearing all data: $e');
    }
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
