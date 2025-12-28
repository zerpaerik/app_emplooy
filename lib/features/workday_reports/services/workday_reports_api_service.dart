import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workday_report_model.dart';

class WorkdayReportsApiService {
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
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // Obtener lista de reportes de una jornada
  Future<List<WorkdayReportModel>> getReports(int contractId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/$contractId/workday-report/'),
        headers: headers,
      );

      print('Get reports response: ${response.statusCode}');
      print('Get reports URL: $baseUrl/api/v-1/workday/$contractId/workday-report/');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        print('Total reports received: ${data.length}');
        if (data.isNotEmpty) {
          print('First report JSON: ${data[0]}');
        }
        return data.map((json) => WorkdayReportModel.fromJson(json)).toList();
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to load reports: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getReports: $e');
      rethrow;
    }
  }

  // Obtener detalle de un reporte específico
  Future<WorkdayReportModel?> getReportDetail(int reportId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/workday-report/$reportId'),
        headers: headers,
      );

      print('Get report detail response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return WorkdayReportModel.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load report detail: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getReportDetail: $e');
      return null;
    }
  }

  // Crear nuevo reporte
  Future<WorkdayReportModel?> createReport(WorkdayReportModel report) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/v-1/workday/${report.workdayId}/workday-report/create'),
        headers: headers,
        body: json.encode(report.toJson()),
      );

      print('Create report response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return WorkdayReportModel.fromJson(data);
      } else {
        print('Error creating report: ${response.body}');
        throw Exception('Failed to create report: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createReport: $e');
      rethrow;
    }
  }

  // Actualizar reporte existente
  Future<WorkdayReportModel?> updateReport(int reportId, WorkdayReportModel report) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/api/v-1/workday/workday-report/$reportId/update'),
        headers: headers,
        body: json.encode(report.toJson()),
      );

      print('Update report response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return WorkdayReportModel.fromJson(data);
      } else {
        throw Exception('Failed to update report: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateReport: $e');
      rethrow;
    }
  }

  // Eliminar reporte
  Future<bool> deleteReport(int reportId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v-1/workday/workday-report/$reportId/delete'),
        headers: headers,
      );

      print('Delete report response: ${response.statusCode}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error in deleteReport: $e');
      return false;
    }
  }

  // Obtener workers con clock-in
  Future<List<Map<String, dynamic>>> getClockedWorkers(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/get-clocked-workers'),
        headers: headers,
      );

      print('Get clocked workers response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error in getClockedWorkers: $e');
      return [];
    }
  }

  // Obtener drivers con clock-in
  Future<List<Map<String, dynamic>>> getClockedDrivers(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/get-clocked-drivers'),
        headers: headers,
      );

      print('Get clocked drivers response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error in getClockedDrivers: $e');
      return [];
    }
  }

  // Obtener workers ausentes
  Future<List<Map<String, dynamic>>> getAbsentWorkers(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/workday-register/absent-list'),
        headers: headers,
      );

      print('Get absent workers response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error in getAbsentWorkers: $e');
      return [];
    }
  }

  // Obtener vehículos disponibles
  Future<List<Map<String, dynamic>>> getAvailableVehicles(int reportId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/workday-report/$reportId/available-vehicles'),
        headers: headers,
      );

      print('Get available vehicles response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error in getAvailableVehicles: $e');
      return [];
    }
  }

  // Obtener lista de clock-in de una jornada
  Future<List<Map<String, dynamic>>> getClockInList(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/clock-in/list'),
        headers: headers,
      );

      print('Get clock-in list response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error in getClockInList: $e');
      return [];
    }
  }

  // Obtener lista de clock-out de una jornada
  Future<List<Map<String, dynamic>>> getClockOutList(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/clock-out/list'),
        headers: headers,
      );

      print('Get clock-out list response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error in getClockOutList: $e');
      return [];
    }
  }

  // Crear reporte base inicial (Step 0)
  Future<Map<String, dynamic>?> createBaseReport(
    int workdayId,
    DateTime? startTime,
    DateTime? endTime,
  ) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'workday_id': workdayId,
        if (startTime != null) 'start_time': startTime.toIso8601String(),
        if (endTime != null) 'end_time': endTime.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/workday-report/create'),
        headers: headers,
        body: json.encode(body),
      );

      print('Create base report response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data;
      } else {
        print('Error creating base report: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error in createBaseReport: $e');
      return null;
    }
  }

  // NUEVOS MÉTODOS SEGÚN FLUJO DE WORKER

  // Step 0: Crear reporte base con had_workday
  Future<int> createReportBase(int workdayId, bool hadWorkday) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'workday': workdayId.toString(),
        'had_workday': hadWorkday,
      };

      print('Creating report base with body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/api/v-1/workday/workday-report/create'),
        headers: headers,
        body: json.encode(body),
      );

      print('Create report base response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final reportId = data['id'];
        print('Report created with ID: $reportId');
        return reportId;
      } else {
        print('Error creating report base: ${response.body}');
        throw Exception('Failed to create report base: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createReportBase: $e');
      rethrow;
    }
  }

  // Step 1: Actualizar lunch duration
  Future<void> updateReportLunch(int reportId, String? duration) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'id': reportId.toString(),
        if (duration != null) 'lunch_duration': '00:$duration:00',
      };

      print('Updating lunch with body: $body');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/v-1/workday/workday-report/$reportId/update'),
        headers: headers,
        body: json.encode(body),
      );

      print('Update lunch response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update lunch: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateReportLunch: $e');
      rethrow;
    }
  }

  // Step 2: Actualizar standby duration
  Future<void> updateReportStandby(int reportId, String? duration) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'id': reportId.toString(),
        if (duration != null) 'standby_duration': '00:$duration:00',
      };

      print('Updating standby with body: $body');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/v-1/workday/workday-report/$reportId/update'),
        headers: headers,
        body: json.encode(body),
      );

      print('Update standby response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update standby: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateReportStandby: $e');
      rethrow;
    }
  }

  // Step 3: Actualizar travel duration
  Future<void> updateReportTravel(int reportId, String? duration) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'id': reportId.toString(),
        if (duration != null) 'travel_duration': '00:$duration:00',
      };

      print('Updating travel with body: $body');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/v-1/workday/workday-report/$reportId/update'),
        headers: headers,
        body: json.encode(body),
      );

      print('Update travel response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update travel: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateReportTravel: $e');
      rethrow;
    }
  }

  // Step 4: Actualizar comments
  Future<void> updateReportComments(int reportId, String? comments) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'id': reportId.toString(),
        if (comments != null && comments.isNotEmpty) 'comments': comments,
      };

      print('Updating comments with body: $body');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/v-1/workday/workday-report/$reportId/update'),
        headers: headers,
        body: json.encode(body),
      );

      print('Update comments response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update comments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateReportComments: $e');
      rethrow;
    }
  }

  // Finalizar jornada después de completar el reporte
  Future<void> finalizeWorkday(int workdayId) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'is_finalized': true,
      };

      print('Finalizing workday with ID: $workdayId');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/v-1/workday/$workdayId/finalize'),
        headers: headers,
        body: json.encode(body),
      );

      print('Finalize workday response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to finalize workday: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in finalizeWorkday: $e');
      rethrow;
    }
  }
}
