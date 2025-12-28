import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workday_model.dart';
import '../models/worker_scan_model.dart';
import '../models/contract_model.dart';
import '../models/worker_clockin_model.dart';

class ClockinApiService {
  static const String baseUrl = 'https://qa.emplooy.com'; // URL real del worker

  // Obtener token de autenticación
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Headers comunes para las peticiones
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // Obtener workday actual (como en worker)
  Future<WorkdayModel?> getCurrentWorkday(int contractId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/get-current'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // El endpoint retorna el workday directamente
        if (data != null && data is Map) {
          return WorkdayModel.fromJson(Map<String, dynamic>.from(data));
        }
        return null;
      } else if (response.statusCode == 404) {
        // No hay workday activo
        return null;
      } else {
        throw Exception('Failed to get current workday: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting current workday: $e');
      return null;
    }
  }

  // Obtener workers del contrato (como en worker)
  Future<List<WorkerScanModel>> getContractWorkers(int contractId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/contract/$contractId/list-workers-accepted'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        // Manejar tanto lista como objeto con workers
        List<dynamic> workersList;
        if (data is List) {
          workersList = data;
        } else if (data is Map && data['workers'] != null) {
          workersList = data['workers'] as List;
        } else {
          workersList = [];
        }
        return workersList.map((w) => WorkerScanModel.fromJson(w)).toList();
      } else if (response.statusCode == 404) {
        // No hay workers aceptados aún, retornar lista vacía
        return [];
      } else {
        throw Exception('Failed to get contract workers: ${response.statusCode}');
      }
    } catch (e) {
      // Si es error de red o 404, retornar lista vacía en lugar de fallar
      print('Error getting contract workers: $e');
      return [];
    }
  }

  // Configurar workday (replicando worker)
  Future<WorkdayModel> setupWorkday({
    required int contractId,
    required DateTime entryTime,
    required String temperature,
    required String location,
    required bool isAutomaticMode,
  }) async {
    // Preparar datos de la petición para debugging
    final requestData = {
      'contract': contractId,
      'clock_in_start': entryTime.toIso8601String(),
      'geographical_coordinates': location,
      'supervisor_temperature': temperature,
      'supervisor_clock': isAutomaticMode,
      'default_entry_time': entryTime.toIso8601String(),
    };
    
    try {
      final headers = await _getHeaders();
      
      // Verificar que tenemos token
      if (headers['Authorization'] == null) {
        throw Exception('Authentication token not found. Please login again.');
      }
      
      final body = json.encode(requestData);

      final response = await http.post(
        Uri.parse('$baseUrl/api/v-1/workday/create'),
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.\n\nData sent:\n${_formatRequestData(requestData)}');
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final workday = WorkdayModel.fromJson(data);
        return workday;
      } else if (response.statusCode == 400) {
        // Bad Request - mostrar detalles del error
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['detail'] ?? errorData.toString();
          throw Exception('Invalid data: $errorMessage\n\nData sent:\n${_formatRequestData(requestData)}');
        } catch (e) {
          throw Exception('Invalid request data (Status 400)\n\nData sent:\n${_formatRequestData(requestData)}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.\n\nData sent:\n${_formatRequestData(requestData)}');
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied. You may not have access to this contract.\n\nData sent:\n${_formatRequestData(requestData)}');
      } else if (response.statusCode == 404) {
        throw Exception('Contract not found (ID: $contractId)\n\nData sent:\n${_formatRequestData(requestData)}');
      } else if (response.statusCode >= 500) {
        String serverError = 'Unknown server error';
        try {
          final errorData = json.decode(response.body);
          serverError = errorData['detail'] ?? errorData.toString();
        } catch (e) {
          serverError = response.body.isNotEmpty ? response.body : 'No error details';
        }
        throw Exception('Server error (${response.statusCode}): $serverError\n\nData sent:\n${_formatRequestData(requestData)}');
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception('Error ${response.statusCode}: ${errorData['detail'] ?? 'Unknown error'}\n\nData sent:\n${_formatRequestData(requestData)}');
        } catch (e) {
          throw Exception('HTTP Error ${response.statusCode}\n\nData sent:\n${_formatRequestData(requestData)}');
        }
      }
    } on http.ClientException {
      throw Exception('Network error: Cannot connect to server. Check your internet connection.\n\nData sent:\n${_formatRequestData(requestData)}');
    } on FormatException {
      throw Exception('Invalid server response format.\n\nData sent:\n${_formatRequestData(requestData)}');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Unexpected error: ${e.toString()}\n\nData sent:\n${_formatRequestData(requestData)}');
    }
  }

  // Helper para formatear datos de request de forma legible
  String _formatRequestData(Map<String, dynamic> data) {
    return data.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');
  }

  // Escanear worker
  Future<WorkerScanModel> scanWorker({
    required String qrCode,
    required int contractId,
    required int workdayId,
    required String location,
    required int scannedByUserId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/user/get-registered-user/$qrCode/$contractId/in'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Registrar el scan
        await _registerWorkerScan(
          workerId: data['id'],
          workdayId: workdayId,
          location: location,
          scannedByUserId: scannedByUserId,
        );

        // Crear modelo con datos de scan
        return WorkerScanModel.fromJson(data).copyWith(
          status: WorkerStatus.scanned,
          scannedAt: DateTime.now(),
          scannedLocation: location,
          scannedByUserId: scannedByUserId,
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['detail'] ?? 'Scan failed';
        
        // Manejar errores específicos
        if (errorMessage == 'The worker has already clocked-in') {
          throw Exception('QR_ALREADY_SCANNED');
        } else if (errorMessage == 'worker not belongs to a project') {
          throw Exception('WORKER_NOT_IN_CONTRACT');
        } else if (errorData['code'] == 'not_match_contract') {
          throw Exception('WRONG_CONTRACT');
        } else {
          throw Exception(errorMessage);
        }
      }
    } catch (e) {
      if (e.toString().contains('QR_') || e.toString().contains('WORKER_') || e.toString().contains('WRONG_')) {
        rethrow;
      }
      throw Exception('Error scanning worker: $e');
    }
  }

  // Registrar scan de worker
  Future<void> _registerWorkerScan({
    required int workerId,
    required int workdayId,
    required String location,
    required int scannedByUserId,
  }) async {
    final headers = await _getHeaders();
    final body = json.encode({
      'worker_id': workerId,
      'workday_id': workdayId,
      'scanned_location': location,
      'scanned_by_user_id': scannedByUserId,
      'scanned_at': DateTime.now().toIso8601String(),
    });

    await http.post(
      Uri.parse('$baseUrl/api/v-1/workday/register-scan'),
      headers: headers,
      body: body,
    );
  }

  // Marcar worker como ausente
  Future<void> markWorkerAbsent({
    required int workerId,
    required int workdayId,
    required AbsenceReason reason,
    String? excuse,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'worker_status': reason.code,
        'absence_excuse': excuse ?? '',
      });

      final response = await http.patch(
        Uri.parse('$baseUrl/api/v-1/workday/workday-register/$workdayId/update-worker-status'),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to mark worker absent');
      }
    } catch (e) {
      throw Exception('Error marking worker absent: $e');
    }
  }

  // Finalizar clock-in
  Future<void> finishClockIn({
    required int workdayId,
    required String location,
    required int finishedByUserId,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'clock_in_finisher': finishedByUserId,
        'clock_in_end': DateTime.now().toIso8601String(),
        'geographical_coordinates': location,
      });

      final response = await http.patch(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/update'),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to finish clock-in');
      }
    } catch (e) {
      throw Exception('Error finishing clock-in: $e');
    }
  }

  // Obtener lista de workers escaneados
  Future<List<WorkerScanModel>> getScannedWorkers(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/scanned-workers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((w) => WorkerScanModel.fromJson(w)).toList();
      } else {
        throw Exception('Failed to get scanned workers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting scanned workers: $e');
    }
  }

  // Obtener lista de workers ausentes
  Future<List<WorkerScanModel>> getAbsentWorkers(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/not-clocked-ins/list'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        List<dynamic> workersList = data is List ? data : [];
        return workersList.map((w) => WorkerScanModel.fromJson(w)).toList();
      } else {
        throw Exception('Failed to get absent workers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting absent workers: $e');
    }
  }

  // Obtener contrato actual completo
  Future<ContractModel> getCurrentContract() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-2/contract/current'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ContractModel.fromJson(data);
      } else {
        throw Exception('Failed to get current contract: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting current contract: $e');
    }
  }

  // Obtener lista de workers que han hecho clock-in (escaneados)
  Future<List<WorkerClockinModel>> getClockedInWorkers(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/clock-in/list'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        List<dynamic> workersList = data is List ? data : [];
        return workersList.map((w) => WorkerClockinModel.fromJson(w)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to get clocked-in workers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting clocked-in workers: $e');
      return [];
    }
  }

  // Actualizar hora de inicio del workday
  Future<WorkdayModel> updateWorkdayInitTime({
    required int workdayId,
    required DateTime newTime,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'default_entry_time': newTime.toIso8601String(),
      });

      final response = await http.patch(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/update'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WorkdayModel.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to update init time');
      }
    } catch (e) {
      throw Exception('Error updating init time: $e');
    }
  }

  // Validar estado actual del workday
  Future<bool> validateWorkdayStatus(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final workday = WorkdayModel.fromJson(data);
        return workday.clockInEnd != null;
      } else {
        return false;
      }
    } catch (e) {
      print('Error validating workday status: $e');
      return false;
    }
  }

  // Hacer clock-in del supervisor
  Future<void> doSupervisorClockin({
    required int workdayId,
    required int userId,
    required String location,
    String? temperature,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'workday': workdayId,
        'worker': userId,
        'clock_type': 'IN',
        'clock_datetime': DateTime.now().toIso8601String(),
        'message': 'Supervisor clock-in',
        'geographical_coordinates': location,
        'verified': true,
        'temperature': temperature ?? '0',
      });

      final response = await http.post(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/workday-register/create'),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to do supervisor clock-in');
      }
    } catch (e) {
      throw Exception('Error doing supervisor clock-in: $e');
    }
  }

  // Verificar worker por QR (como en Worker project)
  Future<Map<String, dynamic>> verifyWorkerQR({
    required String identification,
    required int contractId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/user/get-registered-user/$identification/$contractId/in'),
        headers: headers,
      );

      final resBody = json.decode(utf8.decode(response.bodyBytes));
      
      if (response.statusCode == 200 && resBody['first_name'] != null) {
        return {
          'success': true,
          'data': resBody,
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'data': resBody,
          'statusCode': response.statusCode,
          'error': resBody['detail'] ?? resBody['code'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('Error verifying worker QR: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Registrar clock-in de worker (como en Worker project)
  Future<bool> registerWorkerClockin({
    required int workdayId,
    required int workerId,
    required String location,
    required String defaultEntryTime,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'workday': workdayId,
        'worker': workerId,
        'clock_type': 'IN',
        'clock_datetime': defaultEntryTime,
        'message': 'Worker clock-in',
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
      print('Error registering worker clock-in: $e');
      return false;
    }
  }

  // Finalizar proceso de clock-in
  Future<bool> finishClockin({
    required int workdayId,
    required int supervisorId,
    required String location,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'clock_in_finisher': supervisorId,
        'clock_in_end': DateTime.now().toIso8601String(),
        'geographical_coordinates': location,
      });

      print('Finishing clock-in for workday: $workdayId');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/update'),
        headers: headers,
        body: body,
      );

      print('Finish clock-in response: ${response.statusCode}');
      print('Finish clock-in body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error finishing clock-in: $e');
      return false;
    }
  }
}

