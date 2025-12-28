import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../business/models/location_model.dart';
import '../providers/crew_provider.dart';

class WorkersTab extends ConsumerWidget {
  final Location location;

  const WorkersTab({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crewState = ref.watch(crewProvider);

    if (crewState.isLoading && crewState.workers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (crewState.workers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textGrey),
            const SizedBox(height: 16),
            Text(
              'No workers assigned',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(crewProvider.notifier).fetchWorkers(location.id),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: crewState.workers.length,
        itemBuilder: (context, index) {
          final worker = crewState.workers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: worker.profileImage != null
                    ? NetworkImage(worker.profileImage!)
                    : null,
                child: worker.profileImage == null
                    ? Text(
                        worker.firstName[0].toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(
                worker.fullName,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '#${worker.btnId}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
              trailing: worker.status != null
                  ? Chip(
                      label: Text(
                        worker.status!,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppColors.success,
                    )
                  : null,
              onTap: () {
                _showWorkerDetails(context, worker);
              },
            ),
          );
        },
      ),
    );
  }

  void _showWorkerDetails(BuildContext context, worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (worker.profileImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  worker.profileImage!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      color: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 100,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  size: 100,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              worker.fullName,
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '#${worker.btnId}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
