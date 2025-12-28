import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/worker_report_model.dart';

class WorkerReportService {
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

  // Obtener workers on-time
  Future<List<WorkerReportModel>> getOnTimeWorkers(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/workday-report/worker-report/on-time'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => WorkerReportModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting on-time workers: $e');
      return [];
    }
  }

  // Obtener workers extemporáneos (tarde)
  Future<List<WorkerReportModel>> getExtemporaneousWorkers(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/workday-report/worker-report/extemporaneus'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => WorkerReportModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting extemporaneous workers: $e');
      return [];
    }
  }

  // Obtener workers con standby
  Future<List<WorkerReportModel>> getStandbyWorkers(int reportId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/workday-report/$reportId/worker-report/'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        // Filtrar solo los que tienen standby
        final standbyWorkers = data.where((json) {
          final standbyDuration = json['standby_duration'] as String? ?? '00:00:00';
          return standbyDuration != '00:00:00';
        }).toList();
        
        return standbyWorkers.map((json) => WorkerReportModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting standby workers: $e');
      return [];
    }
  }

  // Obtener todos los workers del reporte organizados por categoría
  Future<Map<WorkerReportCategory, List<WorkerReportModel>>> getAllWorkersByCategory(
    int workdayId,
    int reportId,
  ) async {
    try {
      print('📊 Fetching workers for workday: $workdayId, report: $reportId');
      
      // Obtener todas las listas en paralelo
      final results = await Future.wait([
        getOnTimeWorkers(workdayId),
        getExtemporaneousWorkers(workdayId),
        getStandbyWorkers(reportId),
      ]);

      final onTimeWorkers = results[0];
      final extemporaneousWorkers = results[1];
      final standbyWorkers = results[2];

      print('📊 Raw results:');
      print('   On-time: ${onTimeWorkers.length}');
      print('   Extemporaneous: ${extemporaneousWorkers.length}');
      print('   Standby: ${standbyWorkers.length}');

      // Separar extemporáneos en sin revisar y revisados
      final lateWorkers = extemporaneousWorkers
          .where((w) => w.editorId == null)
          .toList();
      
      final reviewedWorkers = extemporaneousWorkers
          .where((w) => w.editorId != null)
          .toList();

      print('📊 Categorized:');
      print('   Late (unreviewed): ${lateWorkers.length}');
      print('   Reviewed: ${reviewedWorkers.length}');

      return {
        WorkerReportCategory.onTime: onTimeWorkers,
        WorkerReportCategory.late: lateWorkers,
        WorkerReportCategory.reviewed: reviewedWorkers,
        WorkerReportCategory.standby: standbyWorkers,
      };
    } catch (e, stackTrace) {
      print('❌ Error getting all workers by category: $e');
      print('Stack trace: $stackTrace');
      return {
        WorkerReportCategory.onTime: [],
        WorkerReportCategory.late: [],
        WorkerReportCategory.reviewed: [],
        WorkerReportCategory.standby: [],
      };
    }
  }

  // Editar worker individual
  Future<bool> editWorker({
    required int workdayId,
    required int workerId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/worker/$workerId/update'),
        headers: headers,
        body: json.encode(updates),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error editing worker: $e');
      return false;
    }
  }

  // Editar múltiples workers
  Future<bool> editMultipleWorkers({
    required int workdayId,
    required List<int> workerIds,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/workers/bulk-update'),
        headers: headers,
        body: json.encode({
          'worker_ids': workerIds,
          'updates': updates,
        }),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error editing multiple workers: $e');
      return false;
    }
  }

  // Finalizar workday
  Future<bool> finalizeWorkday(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/finalize'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error finalizing workday: $e');
      return false;
    }
  }

  // Enviar reporte
  Future<bool> sendReport(int reportId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/v-1/workday/workday-report/$reportId/send'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error sending report: $e');
      return false;
    }
  }
}
