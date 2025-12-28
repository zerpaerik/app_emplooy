class ApiConstants {
  // URL base del servidor
  static const String baseUrl = 'https://api.emplooy.com'; // Cambiar por la URL real
  
  // Endpoints principales
  static const String authEndpoint = '/api/v-2/auth';
  static const String workdayEndpoint = '/api/v-1/workday';
  static const String contractEndpoint = '/api/v-1/contract';
  static const String userEndpoint = '/api/v-1/user';
  
  // Timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
