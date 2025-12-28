import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/workday_reports_provider.dart';

class StepTravel extends ConsumerStatefulWidget {
  const StepTravel({Key? key}) : super(key: key);

  @override
  ConsumerState<StepTravel> createState() => _StepTravelState();
}

// Key global para acceder al state desde el form_page
final stepTravelKey = GlobalKey<_StepTravelState>();

class _StepTravelState extends ConsumerState<StepTravel> {
  bool? _hadTravel;
  String? _travelDuration;

  // Getters públicos
  bool? get hadTravel => _hadTravel;
  String? get travelDuration => _travelDuration;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(workdayReportsProvider).draftReport;
    if (draft != null && draft.travelTime != null) {
      _hadTravel = true;
      // TODO: Extraer duración del travelTime si está disponible
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          
          Center(
            child: Text(
              'Did you have travel time?',
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
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOptionButton('Yes', true),
              const SizedBox(width: 20),
              _buildOptionButton('No', false),
            ],
          ),
          
          if (_hadTravel == true) ...[
            const SizedBox(height: 40),
            Divider(color: AppColors.borderMedium),
            const SizedBox(height: 24),
            
            Text(
              'Travel duration (minutes)',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDurationDropdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton(String label, bool value) {
    final isSelected = _hadTravel == value;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _hadTravel = value;
            if (!value) {
              _travelDuration = null;
            }
          });
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
                groupValue: _hadTravel,
                onChanged: (val) {
                  setState(() {
                    _hadTravel = val;
                    if (val == false) {
                      _travelDuration = null;
                    }
                  });
                },
                activeColor: isSelected ? Colors.white : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderMedium),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _travelDuration,
          hint: Text(
            'Select duration',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
          items: ['0', '5', '10', '15', '30', '45', '60', '75', '90', '120']
              .map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                '$value minutes',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _travelDuration = value;
            });
          },
        ),
      ),
    );
  }

  // Validar que el step esté completo
  bool isValid() {
    if (_hadTravel == null) return false;
    if (_hadTravel == true && _travelDuration == null) return false;
    return true;
  }

  // Actualizar travel en el reporte
  Future<bool> updateReportTravel() async {
    if (!isValid()) return false;
    
    final reportId = ref.read(workdayReportsProvider).reportId;
    if (reportId == null) return false;

    // Si no tuvo travel, no enviar duración
    final duration = _hadTravel == true ? _travelDuration : null;
    
    final success = await ref.read(workdayReportsProvider.notifier)
        .updateReportTravel(reportId, duration);
    
    return success;
  }
}
