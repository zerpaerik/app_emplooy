import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Servicio de almacenamiento local usando SharedPreferences
class LocalStorage {
  LocalStorage._();

  static final LocalStorage instance = LocalStorage._();

  SharedPreferences? _prefs;

  /// Inicializar SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('LocalStorage not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ========== SHARED PREFERENCES ==========

  /// Guardar token de autenticación
  Future<bool> saveAuthToken(String token) async {
    return await prefs.setString(AppConstants.keyAuthToken, token);
  }

  /// Obtener token de autenticación
  String? getAuthToken() {
    return prefs.getString(AppConstants.keyAuthToken);
  }

  /// Eliminar token de autenticación
  Future<bool> deleteAuthToken() async {
    return await prefs.remove(AppConstants.keyAuthToken);
  }

  /// Guardar ID de usuario
  Future<bool> saveUserId(int userId) async {
    return await prefs.setInt(AppConstants.keyUserId, userId);
  }

  /// Obtener ID de usuario
  int? getUserId() {
    return prefs.getInt(AppConstants.keyUserId);
  }

  /// Guardar email de usuario
  Future<bool> saveUserEmail(String email) async {
    return await prefs.setString(AppConstants.keyUserEmail, email);
  }

  /// Obtener email de usuario
  String? getUserEmail() {
    return prefs.getString(AppConstants.keyUserEmail);
  }

  /// Guardar rol de usuario
  Future<bool> saveUserRole(String role) async {
    return await prefs.setString(AppConstants.keyUserRole, role);
  }

  /// Obtener rol de usuario
  String? getUserRole() {
    return prefs.getString(AppConstants.keyUserRole);
  }

  /// Guardar idioma seleccionado
  Future<bool> saveLanguage(String languageCode) async {
    return await prefs.setString(AppConstants.keyLanguage, languageCode);
  }

  /// Obtener idioma seleccionado
  String getLanguage() {
    return prefs.getString(AppConstants.keyLanguage) ??
        AppConstants.defaultLanguage;
  }

  /// Marcar como usuario logueado
  Future<bool> setLoggedIn(bool value) async {
    return await prefs.setBool(AppConstants.keyIsLoggedIn, value);
  }

  /// Verificar si usuario está logueado
  bool isLoggedIn() {
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  /// Verificar si es primera vez
  bool isFirstTime() {
    return prefs.getBool(AppConstants.keyFirstTime) ?? true;
  }

  /// Marcar que ya no es primera vez
  Future<bool> setNotFirstTime() async {
    return await prefs.setBool(AppConstants.keyFirstTime, false);
  }

  /// Guardar dato genérico String
  Future<bool> saveString(String key, String value) async {
    return await prefs.setString(key, value);
  }

  /// Obtener dato genérico String
  String? getString(String key) {
    return prefs.getString(key);
  }

  /// Guardar dato genérico int
  Future<bool> saveInt(String key, int value) async {
    return await prefs.setInt(key, value);
  }

  /// Obtener dato genérico int
  int? getInt(String key) {
    return prefs.getInt(key);
  }

  /// Guardar dato genérico bool
  Future<bool> saveBool(String key, bool value) async {
    return await prefs.setBool(key, value);
  }

  /// Obtener dato genérico bool
  bool? getBool(String key) {
    return prefs.getBool(key);
  }

  /// Limpiar todos los datos de SharedPreferences
  Future<bool> clearAll() async {
    return await prefs.clear();
  }

  /// Limpiar datos de sesión (logout)
  Future<void> clearSession() async {
    await deleteAuthToken();
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserEmail);
    await prefs.remove(AppConstants.keyUserRole);
    await setLoggedIn(false);
  }
}
