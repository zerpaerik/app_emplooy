import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../business/models/location_model.dart';
import '../providers/crew_provider.dart';

class CrewSheetsTab extends ConsumerWidget {
  final Location location;

  const CrewSheetsTab({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crewState = ref.watch(crewProvider);

    if (crewState.isLoading && crewState.crewSheets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(crewProvider.notifier).fetchCurrentCrew();
        await ref.read(crewProvider.notifier).fetchCrewSheets(location.id);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current Crew Card
          if (crewState.currentCrew != null) ...[
            _buildCurrentCrewCard(context, ref, crewState.currentCrew!),
            const SizedBox(height: 16),
          ],

          // Create Crew Button
          if (crewState.currentCrew == null) ...[
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to create crew
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Create Crew Sheet - Coming soon'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Crew Sheet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Crew Sheets History
          if (crewState.crewSheets.isNotEmpty) ...[
            Text(
              'Crew Sheets History',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...crewState.crewSheets.map((crew) => _buildCrewSheetCard(context, crew)),
          ],

          if (crewState.crewSheets.isEmpty && crewState.currentCrew == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.assignment, size: 64, color: AppColors.textGrey),
                    const SizedBox(height: 16),
                    Text(
                      'No crew sheets yet',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentCrewCard(BuildContext context, WidgetRef ref, crew) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y título
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Active Crew Sheet',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Información del crew
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildEnhancedInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: crew.date ?? 'N/A',
                  valueColor: AppColors.textDark,
                ),
                const SizedBox(height: 12),
                _buildEnhancedInfoRow(
                  icon: Icons.people,
                  label: 'Workers',
                  value: '${crew.workersCount ?? 0}',
                  valueColor: AppColors.primary,
                  isHighlight: true,
                ),
                const SizedBox(height: 12),
                if (crew.entryTime != null) ...[
                  _buildEnhancedInfoRow(
                    icon: Icons.login,
                    label: 'Entry Time',
                    value: crew.entryTime!,
                    valueColor: AppColors.success,
                  ),
                  const SizedBox(height: 12),
                ],
                if (crew.exitTime != null) ...[
                  _buildEnhancedInfoRow(
                    icon: Icons.logout,
                    label: 'Exit Time',
                    value: crew.exitTime!,
                    valueColor: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                ],
                _buildEnhancedInfoRow(
                  icon: Icons.info_outline,
                  label: 'Status',
                  value: crew.status ?? 'Active',
                  valueColor: AppColors.textDark,
                ),
              ],
            ),
          ),

          // Action Buttons
          if (!crew.isCheckInFinished || crew.canStartCheckOut)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  if (!crew.isCheckInFinished)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final success = await ref.read(crewProvider.notifier).endCheckIn(crew.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Check-in finished successfully'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            ref.read(crewProvider.notifier).fetchCurrentCrew();
                          }
                        },
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: const Text(
                          'Finish Check-in',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (crew.canStartCheckOut) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Start Check-out - Coming soon'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text(
                          'Start Check-out',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCrewSheetCard(BuildContext context, crew) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: crew.isCompleted
              ? AppColors.success.withOpacity(0.1)
              : AppColors.warning.withOpacity(0.1),
          child: Icon(
            crew.isCompleted ? Icons.check_circle : Icons.pending,
            color: crew.isCompleted ? AppColors.success : AppColors.warning,
          ),
        ),
        title: Text(
          crew.date,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${crew.workersCount} workers • ${crew.status}',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textGrey),
        onTap: () {
          // TODO: Navigate to crew detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('View Crew Sheet - Coming soon'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textGrey,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primary.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight ? AppColors.primary.withOpacity(0.2) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isHighlight ? AppColors.primary : AppColors.textGrey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
