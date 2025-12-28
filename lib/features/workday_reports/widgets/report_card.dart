import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/workday_report_model.dart';

class ReportCard extends StatelessWidget {
  final WorkdayReportModel report;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onView;
  final VoidCallback? onSend;

  const ReportCard({
    Key? key,
    required this.report,
    required this.onTap,
    this.onEdit,
    this.onView,
    this.onSend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header compacto
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                // Icono de calendario
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                // Fecha y horas trabajadas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM d, yyyy').format(report.reportDate),
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: AppColors.textGrey),
                          const SizedBox(width: 4),
                          Text(
                            report.workedHours != null 
                                ? '${report.workedHours!.toStringAsFixed(1)} hrs'
                                : 'N/A',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Estado
                _buildStatusChip(),
              ],
            ),
          ),
          
          // Comentarios si existen
          if (report.comments != null && report.comments!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.comments!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          
          // Divider sutil
          Divider(
            color: Colors.grey[200],
            thickness: 1,
            height: 1,
          ),
          
          // Tiempos en grid compacto
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _buildTimeColumn(
                  'Clock-in',
                  report.startTime,
                  Icons.login,
                ),
                _buildTimeColumn(
                  'Clock-out',
                  report.endTime,
                  Icons.logout,
                ),
                _buildTimeColumn(
                  'Entry',
                  report.workdayTime?.startTime,
                  Icons.arrow_forward,
                ),
                _buildTimeColumn(
                  'Exit',
                  report.workdayTime?.endTime,
                  Icons.arrow_back,
                ),
              ],
            ),
          ),
          
          // Divider
          Divider(
            color: Colors.grey[200],
            thickness: 1,
            height: 1,
          ),
          
          // Botones de acción compactos
          Row(
            children: [
              _buildActionButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onPressed: onEdit,
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.grey[200],
              ),
              _buildActionButton(
                label: 'View',
                icon: Icons.visibility_outlined,
                onPressed: onView ?? onTap,
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.grey[200],
              ),
              _buildActionButton(
                label: 'Send',
                icon: Icons.send_outlined,
                onPressed: onSend,
                isDisabled: report.isSubmitted || report.isApproved,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String text;
    
    switch (report.status) {
      case 'draft':
      case '1':
        color = Colors.red;
        text = 'Draft';
        break;
      case 'submitted':
      case '2':
        color = Colors.blue;
        text = 'Sent';
        break;
      case 'approved':
      case '3':
        color = Colors.green;
        text = 'Approved';
        break;
      default:
        color = AppColors.textGrey;
        text = 'Draft';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimeColumn(
    String label,
    DateTime? time,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: time != null ? AppColors.primary : AppColors.textGrey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            time != null ? DateFormat('HH:mm').format(time) : 'N/A',
            style: TextStyle(
              fontSize: 13,
              color: time != null ? AppColors.textDark : AppColors.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isDisabled = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          child: Container(
            height: 44,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isDisabled ? Colors.grey : AppColors.primary,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDisabled ? Colors.grey : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
