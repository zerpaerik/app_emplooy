import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/workday_reports_provider.dart';

class StepGeneralInfo extends ConsumerStatefulWidget {
  const StepGeneralInfo({Key? key}) : super(key: key);

  @override
  ConsumerState<StepGeneralInfo> createState() => _StepGeneralInfoState();
}

// Key global para acceder al state desde el form_page
final stepGeneralInfoKey = GlobalKey<_StepGeneralInfoState>();

class _StepGeneralInfoState extends ConsumerState<StepGeneralInfo> {
  bool? _hadWorkday; // No preseleccionar por defecto
  TimeOfDay? _entryTime;
  TimeOfDay? _exitTime;
  DateTime? _earliestClockIn;
  DateTime? _latestClockOut;

  // Getters públicos para acceder desde el form_page
  bool? get hadWorkday => _hadWorkday;
  DateTime? get earliestClockIn => _earliestClockIn;
  DateTime? get latestClockOut => _latestClockOut;

  @override
  void initState() {
    super.initState();
    // No cargar datos automáticamente, esperar a que el usuario seleccione "Yes"
  }

  Future<void> _loadClockInOutTimes() async {
    
    try {
      // Obtener workdayId del provider state
      final reportsState = ref.read(workdayReportsProvider);
      final workdayId = reportsState.workdayId;
      
      if (workdayId == null) {
        print('No workdayId available');
        print('Current state: workdayId=${reportsState.workdayId}, reportId=${reportsState.reportId}');
        return;
      }

      // Obtener token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        print('No token available');
        return;
      }

      final headers = {"Authorization": "Token $token"};
      const baseUrl = 'https://qa.emplooy.com';

      // Consumir endpoints de clock-in y clock-out
      final clockInUrl = Uri.parse('$baseUrl/api/v-1/workday/$workdayId/clock-in/list');
      final clockOutUrl = Uri.parse('$baseUrl/api/v-1/workday/$workdayId/clock-out/list');

      print('Fetching clock-in from: $clockInUrl');
      print('Fetching clock-out from: $clockOutUrl');

      final clockInResp = await http.get(clockInUrl, headers: headers);
      final clockOutResp = await http.get(clockOutUrl, headers: headers);

      print('Clock-in response: ${clockInResp.statusCode}');
      print('Clock-out response: ${clockOutResp.statusCode}');

      final clockInList = (clockInResp.statusCode == 200) 
          ? (json.decode(clockInResp.body) as List) 
          : [];
      final clockOutList = (clockOutResp.statusCode == 200) 
          ? (json.decode(clockOutResp.body) as List) 
          : [];

      print('Clock-in records: ${clockInList.length}');
      print('Clock-out records: ${clockOutList.length}');

      // Obtener el registro más temprano de clock-in (primera entrada del día)
      if (clockInList.isNotEmpty) {
        // Ordenar de más antiguo a más reciente
        clockInList.sort((a, b) => 
          DateTime.parse(a['registration_datetime'])
            .compareTo(DateTime.parse(b['registration_datetime']))
        );
        
        // Tomar el PRIMERO (más temprano)
        final utcClockIn = DateTime.parse(clockInList.first['registration_datetime']);
        _earliestClockIn = utcClockIn.toLocal();
        _entryTime = TimeOfDay.fromDateTime(_earliestClockIn!);
        
        print('=== CLOCK-IN DEBUG ===');
        print('Total clock-ins: ${clockInList.length}');
        print('First clock-in (UTC): $utcClockIn');
        print('First clock-in (Local): $_earliestClockIn');
        print('Entry time to display: ${_entryTime!.format(context)}');
      }

      // Obtener el registro más tardío de clock-out (última salida del día)
      if (clockOutList.isNotEmpty) {
        // Ordenar de más antiguo a más reciente
        clockOutList.sort((a, b) => 
          DateTime.parse(a['registration_datetime'])
            .compareTo(DateTime.parse(b['registration_datetime']))
        );
        
        // Tomar el ÚLTIMO (más tardío)
        final utcClockOut = DateTime.parse(clockOutList.last['registration_datetime']);
        _latestClockOut = utcClockOut.toLocal();
        _exitTime = TimeOfDay.fromDateTime(_latestClockOut!);
        
        print('=== CLOCK-OUT DEBUG ===');
        print('Total clock-outs: ${clockOutList.length}');
        print('Last clock-out (UTC): $utcClockOut');
        print('Last clock-out (Local): $_latestClockOut');
        print('Exit time to display: ${_exitTime!.format(context)}');
      }

      // Actualizar la UI con los datos cargados
      if (mounted) {
        setState(() {});
      }

    } catch (e) {
      print('Error loading clock-in/out times: $e');
    }
  }

  // Validar que el step esté completo
  bool isValid() {
    if (_hadWorkday == null) return false;
    if (_hadWorkday == true && (_entryTime == null || _exitTime == null)) return false;
    return true;
  }

  // Crear el reporte base
  Future<bool> createReportBase() async {
    if (!isValid()) return false;
    
    final workdayId = ref.read(workdayReportsProvider).workdayId;
    if (workdayId == null) return false;

    final reportId = await ref.read(workdayReportsProvider.notifier)
        .createReportBase(workdayId, _hadWorkday!);
    
    return reportId != null;
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(workdayReportsProvider);
    final isLoading = reportsState.isLoading;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo o icono
          Center(
            child: Icon(
              Icons.work_outline,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Pregunta principal
          Center(
            child: Text(
              'Did you have a workday?',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Select an option',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Opciones Sí/No
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOptionButton('Yes', true),
              const SizedBox(width: 20),
              _buildOptionButton('No', false),
            ],
          ),
          
          // Si seleccionó "Sí", mostrar inputs de entrada y salida
          if (_hadWorkday == true) ...[
            const SizedBox(height: 40),
            Divider(color: AppColors.borderMedium),
            const SizedBox(height: 24),
            
            Text(
              'Workday times',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Entry and exit times from clock-in/clock-out',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTimePicker(
              'Entry time',
              _entryTime,
              Icons.login,
              (time) => setState(() => _entryTime = time),
            ),
            const SizedBox(height: 16),
            
            _buildTimePicker(
              'Exit time',
              _exitTime,
              Icons.logout,
              (time) => setState(() => _exitTime = time),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton(String label, bool value) {
    final isSelected = _hadWorkday == value;
    
    return Expanded(
      child: InkWell(
        onTap: () async {
          setState(() {
            _hadWorkday = value;
            if (!value) {
              _entryTime = null;
              _exitTime = null;
              _earliestClockIn = null;
              _latestClockOut = null;
            }
          });
          
          // Si seleccionó "Yes", cargar datos de clock-in/clock-out
          if (value == true) {
            await _loadClockInOutTimes();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderMedium,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isSelected ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Radio<bool>(
                value: value,
                groupValue: _hadWorkday,
                onChanged: (val) async {
                  setState(() {
                    _hadWorkday = val;
                    if (val == false) {
                      _entryTime = null;
                      _exitTime = null;
                      _earliestClockIn = null;
                      _latestClockOut = null;
                    }
                  });
                  
                  // Si seleccionó "Yes", cargar datos de clock-in/clock-out
                  if (val == true) {
                    await _loadClockInOutTimes();
                  }
                },
                activeColor: isSelected ? Colors.white : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay? time,
    IconData icon,
    Function(TimeOfDay) onSelected,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border.all(color: AppColors.borderMedium),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time != null ? time.format(context) : 'Loading...',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline,
            color: AppColors.textGrey,
            size: 20,
          ),
        ],
      ),
    );
  }

}
