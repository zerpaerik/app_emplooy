import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../storage/local_storage.dart';

/// Cliente HTTP simple para manejar requests con autenticación
class HttpClient {
  HttpClient._();

  static final HttpClient instance = HttpClient._();

  final _storage = LocalStorage.instance;

  /// Headers base para todas las peticiones
  Map<String, String> get _baseHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Obtener headers con token de autenticación
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = Map<String, String>.from(_baseHeaders);
    final token = await _storage.getAuthToken();

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }

    return headers;
  }

  /// GET Request
  Future<http.Response> get(
    String endpoint, {
    bool requiresAuth = false,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final headers =
          requiresAuth ? await _getAuthHeaders() : _baseHeaders;

      print('[HttpClient] GET: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(Duration(seconds: AppConstants.connectionTimeout));

      _logResponse(response);
      return response;
    } on SocketException {
      print('[HttpClient] No internet connection');
      rethrow;
    } on HttpException {
      print('[HttpClient] HTTP Error');
      rethrow;
    } catch (e) {
      print('[HttpClient] GET Error: $e');
      rethrow;
    }
  }

  /// POST Request
  Future<http.Response> post(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers =
          requiresAuth ? await _getAuthHeaders() : _baseHeaders;

      print('[HttpClient] POST: $uri');
      print('[HttpClient] Body: ${jsonEncode(body)}');

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: AppConstants.connectionTimeout));

      _logResponse(response);
      return response;
    } on SocketException {
      print('[HttpClient] No internet connection');
      rethrow;
    } on HttpException {
      print('[HttpClient] HTTP Error');
      rethrow;
    } catch (e) {
      print('[HttpClient] POST Error: $e');
      rethrow;
    }
  }

  /// PATCH Request
  Future<http.Response> patch(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers =
          requiresAuth ? await _getAuthHeaders() : _baseHeaders;

      print('[HttpClient] PATCH: $uri');
      print('[HttpClient] Body: ${jsonEncode(body)}');

      final response = await http
          .patch(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: AppConstants.connectionTimeout));

      _logResponse(response);
      return response;
    } on SocketException {
      print('[HttpClient] No internet connection');
      rethrow;
    } on HttpException {
      print('[HttpClient] HTTP Error');
      rethrow;
    } catch (e) {
      print('[HttpClient] PATCH Error: $e');
      rethrow;
    }
  }

  /// DELETE Request
  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final headers = requiresAuth ? await _getAuthHeaders() : _baseHeaders;

      print('[HttpClient] DELETE: $uri');

      final response = await http
          .delete(uri, headers: headers)
          .timeout(Duration(seconds: AppConstants.connectionTimeout));

      _logResponse(response);
      return response;
    } on SocketException {
      print('[HttpClient] No internet connection');
      rethrow;
    } on HttpException {
      print('[HttpClient] HTTP Error');
      rethrow;
    } catch (e) {
      print('[HttpClient] DELETE Error: $e');
      rethrow;
    }
  }

  /// Construir URI con query parameters
  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');

    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }

    return uri;
  }

  /// Loggear respuesta
  void _logResponse(http.Response response) {
    print('[HttpClient] Status Code: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('[HttpClient] Response: ${response.body}');
    } else {
      print('[HttpClient] Error Response: ${response.body}');
    }
  }

  /// Verificar si la respuesta es exitosa
  bool isSuccessful(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Parsear respuesta JSON
  Map<String, dynamic>? parseResponse(http.Response response) {
    try {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('[HttpClient] Error parsing response: $e');
      return null;
    }
  }
}
