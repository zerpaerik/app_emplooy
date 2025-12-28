import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/workday_reports_provider.dart';

class StepSummary extends ConsumerWidget {
  const StepSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsState = ref.watch(workdayReportsProvider);
    final draft = reportsState.draftReport;

    if (draft == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your report before submitting',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSummaryCard(
            'General Information',
            [
              _buildSummaryRow('Date', DateFormat('MMM dd, yyyy').format(draft.reportDate)),
              if (draft.startTime != null)
                _buildSummaryRow('Start Time', DateFormat('HH:mm').format(draft.startTime!)),
              if (draft.endTime != null)
                _buildSummaryRow('End Time', DateFormat('HH:mm').format(draft.endTime!)),
              if (draft.comments != null && draft.comments!.isNotEmpty)
                _buildSummaryRow('Comments', draft.comments!),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildSummaryCard(
            'Personnel',
            [
              _buildSummaryRow('Workers', '${draft.totalWorkers}'),
              if (draft.totalDrivers > 0)
                _buildSummaryRow('Drivers', '${draft.totalDrivers}'),
              if (draft.totalAbsent > 0)
                _buildSummaryRow('Absent', '${draft.totalAbsent}'),
            ],
          ),
          const SizedBox(height: 16),
          
          if (draft.workdayTime != null || draft.lunchTime != null || 
              draft.standbyTime != null || draft.travelTime != null)
            _buildSummaryCard(
              'Time Breakdown',
              [
                if (draft.workdayTime != null)
                  _buildSummaryRow('Workday', draft.workdayTime!.durationFormatted),
                if (draft.lunchTime != null)
                  _buildSummaryRow('Lunch', draft.lunchTime!.durationFormatted),
                if (draft.standbyTime != null)
                  _buildSummaryRow('Standby', draft.standbyTime!.durationFormatted),
                if (draft.travelTime != null)
                  _buildSummaryRow('Travel', draft.travelTime!.durationFormatted),
              ],
            ),
          const SizedBox(height: 16),
          
          if (draft.vehicleIds.isNotEmpty || draft.equipment != null || draft.materials != null)
            _buildSummaryCard(
              'Resources',
              [
                if (draft.vehicleIds.isNotEmpty)
                  _buildSummaryRow('Vehicles', '${draft.totalVehicles}'),
                if (draft.equipment != null)
                  _buildSummaryRow('Equipment', draft.equipment!),
                if (draft.materials != null)
                  _buildSummaryRow('Materials', draft.materials!),
              ],
            ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ready to submit! Click "Submit Report" to save this workday report.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
