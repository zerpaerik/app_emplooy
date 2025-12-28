import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../business/providers/business_provider.dart';

class DashboardBusiness extends ConsumerWidget {
  const DashboardBusiness({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cargar métricas al iniciar
    ref.listen(businessProvider, (previous, next) {
      if (previous == null && next.metrics == null && !next.isLoading) {
        Future.microtask(() => ref.read(businessProvider.notifier).fetchMetrics());
      }
    });

    final businessState = ref.watch(businessProvider);
    final metrics = businessState.metrics;

    if (businessState.isLoading && metrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (businessState.error != null && metrics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              businessState.error!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(businessProvider.notifier).refreshMetrics(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(businessProvider.notifier).refreshMetrics(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Metrics',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Overview of your business operations',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
            ),
            const SizedBox(height: 24),

            _buildStatusFilters(ref),
            const SizedBox(height: 24),

            if (metrics != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Clocked-in',
                      value: metrics.todayClockIns.toString(),
                      subtitle: 'Today',
                      icon: Icons.login,
                      color: AppColors.primary,
                      trend: metrics.hasIncreasedClockIns ? 'up' : 
                             metrics.hasEqualClockIns ? 'equal' : 'down',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Absents',
                      value: metrics.todayAbsents.toString(),
                      subtitle: 'Today',
                      icon: Icons.person_off,
                      color: AppColors.warning,
                      trend: metrics.hasDecreasedAbsents ? 'up' : 
                             metrics.hasEqualAbsents ? 'equal' : 'down',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Locations',
                      value: metrics.totalLocations.toString(),
                      subtitle: 'Active',
                      icon: Icons.location_on,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Yesterday',
                      value: metrics.yesterdayClockIns.toString(),
                      subtitle: 'Clock-ins',
                      icon: Icons.history,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (metrics.coordinates.isNotEmpty) ...[
                Text(
                  'Active Locations',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...metrics.coordinates.map((location) => _buildLocationCard(location)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilters(WidgetRef ref) {
    final businessState = ref.watch(businessProvider);
    final selectedStatus = businessState.selectedStatus;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(ref, 'Active', 'active', selectedStatus),
          const SizedBox(width: 8),
          _buildFilterChip(ref, 'Inactive', 'inactive', selectedStatus),
          const SizedBox(width: 8),
          _buildFilterChip(ref, 'Finished', 'finished', selectedStatus),
          const SizedBox(width: 8),
          _buildFilterChip(ref, 'All', 'all', selectedStatus),
        ],
      ),
    );
  }

  Widget _buildFilterChip(WidgetRef ref, String label, String value, String selectedStatus) {
    final isSelected = value == selectedStatus;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(businessProvider.notifier).changeStatus(value);
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textGrey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                if (trend != null)
                  Icon(
                    trend == 'up' ? Icons.arrow_upward :
                    trend == 'down' ? Icons.arrow_downward :
                    Icons.swap_vert,
                    color: trend == 'up' ? Colors.green :
                           trend == 'down' ? Colors.red :
                           Colors.blue,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.h1.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGrey),
            ),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(location) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(Icons.location_on, color: AppColors.primary),
        ),
        title: Text(
          location.contractName,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(location.address),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: AppColors.textGrey),
                const SizedBox(width: 4),
                Text(
                  '${location.clockedIns}/${location.numberOfWorkers} workers',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textGrey),
        onTap: () {},
      ),
    );
  }
}
