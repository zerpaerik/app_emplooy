import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../business/models/location_model.dart';

class LocationCard extends StatelessWidget {
  final Location location;
  final VoidCallback onTap;
  final VoidCallback? onSubLocationsTap;

  const LocationCard({
    super.key,
    required this.location,
    required this.onTap,
    this.onSubLocationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Name and SubLocations Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      location.name,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (location.hasSubLocations && onSubLocationsTap != null)
                    GestureDetector(
                      onTap: onSubLocationsTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'SubLocations: ${location.subLocations!.length}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),

              // Address
              Text(
                location.firstAddress,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetric(
                      label: 'Clocked-in',
                      value: location.todayClockIns.toString(),
                      subtitle: 'Today',
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      label: 'Absents',
                      value: location.todayAbsents.toString(),
                      subtitle: 'Today',
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      label: 'Worked hours',
                      value: location.yesterdayWh.toString(),
                      subtitle: 'Yesterday',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textGrey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.h2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }
}
