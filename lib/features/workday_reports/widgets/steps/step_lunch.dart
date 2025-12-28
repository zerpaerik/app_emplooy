import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/workday_reports_provider.dart';

class StepLunch extends ConsumerStatefulWidget {
  const StepLunch({Key? key}) : super(key: key);

  @override
  ConsumerState<StepLunch> createState() => _StepLunchState();
}

// Key global para acceder al state desde el form_page
final stepLunchKey = GlobalKey<_StepLunchState>();

class _StepLunchState extends ConsumerState<StepLunch> {
  bool? _hadLunch;
  String? _lunchDuration;

  // Getters públicos
  bool? get hadLunch => _hadLunch;
  String? get lunchDuration => _lunchDuration;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(workdayReportsProvider).draftReport;
    if (draft != null && draft.lunchTime != null) {
      _hadLunch = true;
      // TODO: Extraer duración del lunchTime si está disponible
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
              Icons.restaurant_outlined,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          
          Center(
            child: Text(
              'Did you have lunch?',
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
          
          if (_hadLunch == true) ...[
            const SizedBox(height: 40),
            Divider(color: AppColors.borderMedium),
            const SizedBox(height: 24),
            
            Text(
              'Lunch duration (minutes)',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildLunchDurationDropdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton(String label, bool value) {
    final isSelected = _hadLunch == value;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _hadLunch = value;
            if (!value) {
              _lunchDuration = null;
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
                groupValue: _hadLunch,
                onChanged: (val) {
                  setState(() {
                    _hadLunch = val;
                    if (val == false) {
                      _lunchDuration = null;
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

  Widget _buildLunchDurationDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderMedium),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _lunchDuration,
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
              _lunchDuration = value;
            });
          },
        ),
      ),
    );
  }

  // Validar que el step esté completo
  bool isValid() {
    if (_hadLunch == null) return false;
    if (_hadLunch == true && _lunchDuration == null) return false;
    return true;
  }

  // Actualizar lunch en el reporte
  Future<bool> updateReportLunch() async {
    if (!isValid()) return false;
    
    final reportId = ref.read(workdayReportsProvider).reportId;
    if (reportId == null) return false;

    // Si no tuvo lunch, no enviar duración
    final duration = _hadLunch == true ? _lunchDuration : null;
    
    final success = await ref.read(workdayReportsProvider.notifier)
        .updateReportLunch(reportId, duration);
    
    return success;
  }
}
