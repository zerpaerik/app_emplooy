import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ClockoutApiService {
  static const String baseUrl = 'https://qa.emplooy.com';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Token $token',
    };
  }

  // Obtener workday actual (mismo endpoint que Clock In)
  Future<Map<String, dynamic>> getCurrentWorkday(int contractId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/get-current'),
        headers: headers,
      );

      print('Get current workday response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 404) {
        // No hay workday activo
        return {
          'success': false,
          'error': 'No workday found',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get workday: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error getting current workday: $e');
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  // Iniciar proceso de clock-out (como en Worker)
  Future<bool> startClockoutProcess({
    required int workdayId,
    required String clockOutStart,
    required String defaultExitTime,
    required bool supervisorClock,
    required String location,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'clock_out_start': clockOutStart,
        'geographical_coordinates': location,
        'supervisor_clock': supervisorClock,
        'default_exit_time': defaultExitTime,
      });

      print('Starting clockout process for workday: $workdayId');
      print('Body: $body');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/update'),
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
      );

      print('Start clockout response: ${response.statusCode}');
      print('Start clockout body: ${response.body}');

      // Verificar status codes exitosos (200, 201, 202)
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error starting clockout: $e');
      return false;
    }
  }

  // Verificar worker por QR para clock-out
  Future<Map<String, dynamic>> verifyWorkerQR({
    required String identification,
    required int contractId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/user/get-registered-user/$identification/$contractId/out'),
        headers: headers,
      );

      print('Verify worker QR response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        // Verificar si hay errores específicos
        if (data['detail'] != null) {
          String errorMessage = data['detail'];
          if (errorMessage == 'The worker has already clocked out') {
            return {
              'success': false,
              'error': 'QR ALREADY SCANNED',
              'message': 'This worker has already clocked out',
            };
          } else if (errorMessage == 'The worker has not clocked in') {
            return {
              'success': false,
              'error': 'NO CLOCK IN',
              'message': 'This worker has not clocked in yet',
            };
          } else if (errorMessage == 'worker not belongs to a project') {
            return {
              'success': false,
              'error': 'WORKER NOT IN CONTRACT',
              'message': 'This worker does not belong to this contract',
            };
          }
        }

        // Worker válido
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'WORKER NOT FOUND',
          'message': 'Worker not found in the system',
        };
      } else {
        return {
          'success': false,
          'error': 'VERIFICATION FAILED',
          'message': 'Failed to verify worker',
        };
      }
    } catch (e) {
      print('Error verifying worker QR: $e');
      return {
        'success': false,
        'error': 'ERROR',
        'message': 'Error verifying worker: $e',
      };
    }
  }

  // Registrar clock-out de worker
  Future<bool> registerWorkerClockout({
    required int workdayId,
    required int workerId,
    required String location,
    required String defaultExitTime,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'workday': workdayId,
        'worker': workerId,
        'clock_type': 'OUT',
        'clock_datetime': defaultExitTime,
        'message': 'Worker clock-out',
        'geographical_coordinates': location,
        'verified': true,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/workday-register/create'),
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 15),
      );

      // Verificar status codes exitosos (200, 201, 202)
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error registering worker clock-out: $e');
      return false;
    }
  }

  // Obtener lista de workers con clock-out
  Future<List<Map<String, dynamic>>> getClockedOutWorkers(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/clock-out/list'),
        headers: headers,
      );

      print('Get clocked out workers response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting clocked out workers: $e');
      return [];
    }
  }

  // Obtener workers pendientes (sin clock-out) - como en Worker
  Future<List<Map<String, dynamic>>> getPendingWorkers(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/not-clocked-outs/list'),
        headers: headers,
      );

      print('Get pending workers response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting pending workers: $e');
      return [];
    }
  }

  // Finalizar proceso de clock-out
  Future<bool> finishClockout({
    required int workdayId,
    required int supervisorId,
    required String location,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'clock_out_finisher': supervisorId,
        'clock_out_end': DateTime.now().toIso8601String(),
        'geographical_coordinates': location,
      });

      print('Finishing clock-out for workday: $workdayId');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/update'),
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
      );

      print('Finish clock-out response: ${response.statusCode}');
      print('Finish clock-out body: ${response.body}');

      // Verificar status codes exitosos (200, 201, 202)
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error finishing clock-out: $e');
      return false;
    }
  }

  // Clock-out del supervisor
  Future<bool> supervisorClockout({
    required int workdayId,
    required int supervisorId,
    required String location,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'workday': workdayId,
        'worker': supervisorId,
        'clock_type': 'OUT',
        'clock_datetime': DateTime.now().toIso8601String(),
        'message': 'Supervisor clock-out',
        'geographical_coordinates': location,
        'verified': true,
      });

      print('Supervisor clock-out: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/workday-register/create'),
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
      );

      print('Supervisor clock-out response: ${response.statusCode}');

      // Verificar status codes exitosos (200, 201, 202)
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error supervisor clock-out: $e');
      return false;
    }
  }
}
