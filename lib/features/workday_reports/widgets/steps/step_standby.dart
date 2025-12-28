import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/workday_reports_provider.dart';

class StepStandby extends ConsumerStatefulWidget {
  const StepStandby({Key? key}) : super(key: key);

  @override
  ConsumerState<StepStandby> createState() => _StepStandbyState();
}

// Key global para acceder al state desde el form_page
final stepStandbyKey = GlobalKey<_StepStandbyState>();

class _StepStandbyState extends ConsumerState<StepStandby> {
  bool? _hadStandby;
  String? _standbyDuration;

  // Getters públicos
  bool? get hadStandby => _hadStandby;
  String? get standbyDuration => _standbyDuration;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(workdayReportsProvider).draftReport;
    if (draft != null && draft.standbyTime != null) {
      _hadStandby = true;
      // TODO: Extraer duración del standbyTime si está disponible
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
              Icons.pause_circle_outline,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          
          Center(
            child: Text(
              'Did you have standby time?',
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
          
          if (_hadStandby == true) ...[
            const SizedBox(height: 40),
            Divider(color: AppColors.borderMedium),
            const SizedBox(height: 24),
            
            Text(
              'Standby duration (minutes)',
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
    final isSelected = _hadStandby == value;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _hadStandby = value;
            if (!value) {
              _standbyDuration = null;
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
                groupValue: _hadStandby,
                onChanged: (val) {
                  setState(() {
                    _hadStandby = val;
                    if (val == false) {
                      _standbyDuration = null;
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
          value: _standbyDuration,
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
              _standbyDuration = value;
            });
          },
        ),
      ),
    );
  }

  // Validar que el step esté completo
  bool isValid() {
    if (_hadStandby == null) return false;
    if (_hadStandby == true && _standbyDuration == null) return false;
    return true;
  }

  // Actualizar standby en el reporte
  Future<bool> updateReportStandby() async {
    if (!isValid()) return false;
    
    final reportId = ref.read(workdayReportsProvider).reportId;
    if (reportId == null) return false;

    // Si no tuvo standby, no enviar duración
    final duration = _hadStandby == true ? _standbyDuration : null;
    
    final success = await ref.read(workdayReportsProvider.notifier)
        .updateReportStandby(reportId, duration);
    
    return success;
  }
}
