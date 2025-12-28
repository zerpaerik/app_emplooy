import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/workday_reports_provider.dart';

class StepResources extends ConsumerStatefulWidget {
  const StepResources({Key? key}) : super(key: key);

  @override
  ConsumerState<StepResources> createState() => _StepResourcesState();
}

class _StepResourcesState extends ConsumerState<StepResources> {
  final _equipmentController = TextEditingController();
  final _materialsController = TextEditingController();
  Set<int> selectedVehicles = {};

  @override
  void initState() {
    super.initState();
    final draft = ref.read(workdayReportsProvider).draftReport;
    if (draft != null) {
      selectedVehicles = Set.from(draft.vehicleIds);
      _equipmentController.text = draft.equipment ?? '';
      _materialsController.text = draft.materials ?? '';
    }
  }

  @override
  void dispose() {
    _equipmentController.dispose();
    _materialsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(workdayReportsProvider);
    final vehicles = reportsState.availableVehicles;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resources',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select vehicles and record equipment used',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 24),
          
          if (vehicles.isNotEmpty) ...[
            Text(
              'Vehicles',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...vehicles.map((vehicle) => _buildVehicleCheckbox(vehicle)),
            const SizedBox(height: 24),
          ],
          
          Text(
            'Equipment',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _equipmentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'List equipment used...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (_) => _updateDraft(),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Materials',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _materialsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'List materials used...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (_) => _updateDraft(),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCheckbox(Map<String, dynamic> vehicle) {
    final id = vehicle['id'] as int? ?? 0;
    final name = vehicle['name'] as String? ?? vehicle['vehicle_name'] as String? ?? 'Unknown';
    final plate = vehicle['plate'] as String? ?? vehicle['license_plate'] as String? ?? '';
    final isSelected = selectedVehicles.contains(id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              selectedVehicles.add(id);
            } else {
              selectedVehicles.remove(id);
            }
          });
          _updateDraft();
        },
        title: Text(
          name,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: plate.isNotEmpty
            ? Text(
                'Plate: $plate',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textGrey,
                ),
              )
            : null,
        activeColor: AppColors.primary,
      ),
    );
  }

  void _updateDraft() {
    final draft = ref.read(workdayReportsProvider).draftReport;
    if (draft == null) return;

    final updatedDraft = draft.copyWith(
      vehicleIds: selectedVehicles.toList(),
      equipment: _equipmentController.text.isEmpty ? null : _equipmentController.text,
      materials: _materialsController.text.isEmpty ? null : _materialsController.text,
    );

    ref.read(workdayReportsProvider.notifier).updateDraftReport(updatedDraft);
  }
}
