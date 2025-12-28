/// Constantes globales de la aplicación Emplooy
class AppConstants {
  AppConstants._();

  // API Configuration
  static const String baseUrl = 'https://qa.emplooy.com';
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // Endpoints
  static const String apiAuthLogin = '/api/v-2/auth/login';
  static const String apiAuthLogout = '/api/v-1/auth/logout';
  static const String apiRegisterUser = '/api/v-1/user/register';
  static const String apiVerifyEmail = '/api/v-1/auth/verify_email';
  static const String apiVerifyCode = '/api/v-1/auth/verify_code';
  static const String apiForgotPassword = '/api/v-1/auth/forgot_password';
  static const String apiChangePassword = '/api/v-1/auth/change_password';
  static const String apiGetUserProfile = '/api/v-1/user/get_user_profile';
  static const String apiUpdateProfile = '/api/v-1/user/profile_update';

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserRole = 'user_role';
  static const String keyLanguage = 'selected_language';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyFirstTime = 'first_time';

  // Default Values
  static const String defaultLanguage = 'en';
  static const String defaultRole = 'worker';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int verificationCodeLength = 6;

  // Assets
  static const String logoPath = 'assets/images/logo.png';
  static const String logoWhitePath = 'assets/images/logo_white.png';
}
