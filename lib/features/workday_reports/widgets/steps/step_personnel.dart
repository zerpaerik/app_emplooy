import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/workday_reports_provider.dart';

class StepPersonnel extends ConsumerStatefulWidget {
  const StepPersonnel({Key? key}) : super(key: key);

  @override
  ConsumerState<StepPersonnel> createState() => _StepPersonnelState();
}

class _StepPersonnelState extends ConsumerState<StepPersonnel> {
  Set<int> selectedWorkers = {};
  Set<int> selectedDrivers = {};

  @override
  void initState() {
    super.initState();
    final draft = ref.read(workdayReportsProvider).draftReport;
    if (draft != null) {
      selectedWorkers = Set.from(draft.workerIds);
      selectedDrivers = Set.from(draft.driverIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(workdayReportsProvider);
    final workers = reportsState.availableWorkers;
    final drivers = reportsState.availableDrivers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personnel Selection',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the workers and drivers who worked on this day',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 24),
          
          if (workers.isNotEmpty) ...[
            _buildSectionHeader('Workers', workers.length, selectedWorkers.length),
            const SizedBox(height: 12),
            ...workers.map((worker) => _buildWorkerCheckbox(worker, true)),
            const SizedBox(height: 24),
          ],
          
          if (drivers.isNotEmpty) ...[
            _buildSectionHeader('Drivers', drivers.length, selectedDrivers.length),
            const SizedBox(height: 12),
            ...drivers.map((driver) => _buildWorkerCheckbox(driver, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int total, int selected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$selected / $total selected',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerCheckbox(Map<String, dynamic> person, bool isWorker) {
    final id = person['id'] as int? ?? person['worker_id'] as int? ?? 0;
    final name = '${person['first_name'] ?? ''} ${person['last_name'] ?? ''}'.trim();
    final btnId = person['btn_id'] as String? ?? '';
    final isSelected = isWorker ? selectedWorkers.contains(id) : selectedDrivers.contains(id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              if (isWorker) {
                selectedWorkers.add(id);
              } else {
                selectedDrivers.add(id);
              }
            } else {
              if (isWorker) {
                selectedWorkers.remove(id);
              } else {
                selectedDrivers.remove(id);
              }
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
        subtitle: Text(
          'ID: $btnId',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textGrey,
          ),
        ),
        activeColor: AppColors.primary,
      ),
    );
  }

  void _updateDraft() {
    final draft = ref.read(workdayReportsProvider).draftReport;
    if (draft == null) return;

    final updatedDraft = draft.copyWith(
      workerIds: selectedWorkers.toList(),
      driverIds: selectedDrivers.toList(),
    );

    ref.read(workdayReportsProvider.notifier).updateDraftReport(updatedDraft);
  }
}
