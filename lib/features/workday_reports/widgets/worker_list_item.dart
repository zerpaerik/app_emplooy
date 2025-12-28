import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/worker_report_model.dart';

class WorkerListItem extends StatelessWidget {
  final WorkerReportModel worker;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final ValueChanged<bool>? onSelectionChanged;

  const WorkerListItem({
    Key? key,
    required this.worker,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (onSelectionChanged != null)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelectionChanged?.call(value ?? false),
                  activeColor: AppColors.primary,
                ),
              _buildRoleIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ID#${worker.btnId}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (worker.isLate)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Late',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      worker.fullName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      worker.roleName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: onEdit,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleIcon() {
    IconData iconData;
    Color iconColor;

    if (worker.isSupervisor) {
      iconData = Icons.supervisor_account;
      iconColor = Colors.purple;
    } else if (worker.isLead) {
      iconData = Icons.engineering;
      iconColor = Colors.blue;
    } else if (worker.wasDriver) {
      iconData = Icons.local_shipping;
      iconColor = Colors.green;
    } else {
      iconData = Icons.person;
      iconColor = AppColors.textGrey;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }
}
