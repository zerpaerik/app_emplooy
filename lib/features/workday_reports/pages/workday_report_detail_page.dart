import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/workday_report_model.dart';

class WorkdayReportDetailPage extends StatelessWidget {
  final WorkdayReportModel report;

  const WorkdayReportDetailPage({
    Key? key,
    required this.report,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Report Detail',
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildPersonnelCard(),
            const SizedBox(height: 16),
            _buildTimesCard(),
            const SizedBox(height: 16),
            if (report.vehicleIds.isNotEmpty || report.equipment != null)
              _buildResourcesCard(),
            if (report.comments != null && report.comments!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCommentsCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM dd, yyyy').format(report.reportDate),
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 16),
          if (report.startTime != null && report.endTime != null) ...[
            _buildInfoRow(
              Icons.access_time,
              'Start Time',
              DateFormat('HH:mm').format(report.startTime!),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time_filled,
              'End Time',
              DateFormat('HH:mm').format(report.endTime!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonnelCard() {
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
            'Personnel',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.people,
            'Workers',
            '${report.totalWorkers}',
          ),
          if (report.totalDrivers > 0) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.local_shipping,
              'Drivers',
              '${report.totalDrivers}',
            ),
          ],
          if (report.totalAbsent > 0) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.person_off,
              'Absent',
              '${report.totalAbsent}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimesCard() {
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
            'Time Breakdown',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (report.workdayTime != null)
            _buildTimeSection('Workday', report.workdayTime!),
          if (report.lunchTime != null) ...[
            const Divider(height: 24),
            _buildTimeSection('Lunch', report.lunchTime!),
          ],
          if (report.standbyTime != null) ...[
            const Divider(height: 24),
            _buildTimeSection('Standby', report.standbyTime!),
          ],
          if (report.travelTime != null) ...[
            const Divider(height: 24),
            _buildTimeSection('Travel', report.travelTime!),
          ],
        ],
      ),
    );
  }

  Widget _buildResourcesCard() {
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
            'Resources',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (report.vehicleIds.isNotEmpty)
            _buildInfoRow(
              Icons.directions_car,
              'Vehicles',
              '${report.totalVehicles}',
            ),
          if (report.equipment != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.build,
              'Equipment',
              report.equipment!,
            ),
          ],
          if (report.materials != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.inventory,
              'Materials',
              report.materials!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsCard() {
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
            'Comments',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            report.comments!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection(String title, timeModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (timeModel.startTime != null && timeModel.endTime != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start: ${DateFormat('HH:mm').format(timeModel.startTime!)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
              Text(
                'End: ${DateFormat('HH:mm').format(timeModel.endTime!)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Duration: ${timeModel.durationFormatted}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String text;
    
    switch (report.status) {
      case 'draft':
        color = AppColors.textGrey;
        text = 'Draft';
        break;
      case 'submitted':
        color = AppColors.warning;
        text = 'Submitted';
        break;
      case 'approved':
        color = AppColors.success;
        text = 'Approved';
        break;
      default:
        color = AppColors.textGrey;
        text = report.status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
