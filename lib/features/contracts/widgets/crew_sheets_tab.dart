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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Active Crew Sheet',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Date', crew.date),
            if (crew.entryTime != null)
              _buildInfoRow('Entry Time', crew.entryTime!),
            if (crew.exitTime != null)
              _buildInfoRow('Exit Time', crew.exitTime!),
            _buildInfoRow('Workers', '${crew.workersCount}'),
            _buildInfoRow('Status', crew.status),
            const SizedBox(height: 16),

            // Action Buttons
            if (!crew.isCheckInFinished)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Finish Check-in'),
                ),
              ),
            if (crew.canStartCheckOut)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Start check-out
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Start Check-out - Coming soon'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Start Check-out'),
                ),
              ),
          ],
        ),
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
}
