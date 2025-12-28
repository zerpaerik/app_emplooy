import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/workday_reports_provider.dart';
import '../../models/report_time_model.dart';

class StepTimes extends ConsumerStatefulWidget {
  const StepTimes({Key? key}) : super(key: key);

  @override
  ConsumerState<StepTimes> createState() => _StepTimesState();
}

class _StepTimesState extends ConsumerState<StepTimes> {
  TimeOfDay? workdayStart;
  TimeOfDay? workdayEnd;
  TimeOfDay? lunchStart;
  TimeOfDay? lunchEnd;
  TimeOfDay? standbyStart;
  TimeOfDay? standbyEnd;
  TimeOfDay? travelStart;
  TimeOfDay? travelEnd;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Breakdown',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Record the time spent on different activities',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildTimeSection('Workday Time', workdayStart, workdayEnd, (start, end) {
            setState(() {
              workdayStart = start;
              workdayEnd = end;
            });
            _updateDraft();
          }),
          const SizedBox(height: 20),
          
          _buildTimeSection('Lunch Time', lunchStart, lunchEnd, (start, end) {
            setState(() {
              lunchStart = start;
              lunchEnd = end;
            });
            _updateDraft();
          }),
          const SizedBox(height: 20),
          
          _buildTimeSection('Standby Time', standbyStart, standbyEnd, (start, end) {
            setState(() {
              standbyStart = start;
              standbyEnd = end;
            });
            _updateDraft();
          }),
          const SizedBox(height: 20),
          
          _buildTimeSection('Travel Time', travelStart, travelEnd, (start, end) {
            setState(() {
              travelStart = start;
              travelEnd = end;
            });
            _updateDraft();
          }),
        ],
      ),
    );
  }

  Widget _buildTimeSection(
    String title,
    TimeOfDay? start,
    TimeOfDay? end,
    Function(TimeOfDay?, TimeOfDay?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeButton('Start', start, () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: start ?? TimeOfDay.now(),
                  );
                  if (time != null) {
                    onChanged(time, end);
                  }
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeButton('End', end, () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: end ?? TimeOfDay.now(),
                  );
                  if (time != null) {
                    onChanged(start, time);
                  }
                }),
              ),
            ],
          ),
          if (start != null && end != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${_calculateDuration(start, end)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeButton(String label, TimeOfDay? time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderMedium),
          borderRadius: BorderRadius.circular(8),
        ),
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
              time?.format(context) ?? '--:--',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateDuration(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final duration = endMinutes - startMinutes;
    
    if (duration < 0) return '--:--';
    
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  void _updateDraft() {
    final draft = ref.read(workdayReportsProvider).draftReport;
    if (draft == null) return;

    final now = DateTime.now();

    final updatedDraft = draft.copyWith(
      workdayTime: workdayStart != null && workdayEnd != null
          ? ReportTimeModel(
              startTime: DateTime(now.year, now.month, now.day, workdayStart!.hour, workdayStart!.minute),
              endTime: DateTime(now.year, now.month, now.day, workdayEnd!.hour, workdayEnd!.minute),
            )
          : null,
      lunchTime: lunchStart != null && lunchEnd != null
          ? ReportTimeModel(
              startTime: DateTime(now.year, now.month, now.day, lunchStart!.hour, lunchStart!.minute),
              endTime: DateTime(now.year, now.month, now.day, lunchEnd!.hour, lunchEnd!.minute),
            )
          : null,
      standbyTime: standbyStart != null && standbyEnd != null
          ? ReportTimeModel(
              startTime: DateTime(now.year, now.month, now.day, standbyStart!.hour, standbyStart!.minute),
              endTime: DateTime(now.year, now.month, now.day, standbyEnd!.hour, standbyEnd!.minute),
            )
          : null,
      travelTime: travelStart != null && travelEnd != null
          ? ReportTimeModel(
              startTime: DateTime(now.year, now.month, now.day, travelStart!.hour, travelStart!.minute),
              endTime: DateTime(now.year, now.month, now.day, travelEnd!.hour, travelEnd!.minute),
            )
          : null,
    );

    ref.read(workdayReportsProvider.notifier).updateDraftReport(updatedDraft);
  }
}
