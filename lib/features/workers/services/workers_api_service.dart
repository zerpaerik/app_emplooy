import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/worker_model.dart';

class WorkersApiService {
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

  // Obtener lista de workers de un contrato
  Future<List<WorkerModel>> getWorkers(int contractId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/crew/$contractId/workers'),
        headers: headers,
      );

      print('Get workers response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        print('Total workers received: ${data.length}');
        
        // Convertir cada worker y hacer log
        final workers = data.map((json) => WorkerModel.fromJson(json)).toList();
        return workers;
      } else {
        print('Error getting workers: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load workers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getWorkers: $e');
      rethrow;
    }
  }

  // Obtener detalle de un worker específico
  Future<WorkerModel?> getWorkerDetail(int workerId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v-1/worker/$workerId'),
        headers: headers,
      );

      print('Get worker detail response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return WorkerModel.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load worker detail: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getWorkerDetail: $e');
      return null;
    }
  }
}
