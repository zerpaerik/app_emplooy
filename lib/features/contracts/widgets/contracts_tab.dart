import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../business/models/location_model.dart';
import '../providers/contracts_provider.dart';

class ContractsTab extends ConsumerWidget {
  final Location location;

  const ContractsTab({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsState = ref.watch(contractsProvider);

    if (contractsState.isLoading && contractsState.contracts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (contractsState.error != null && contractsState.contracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              contractsState.error!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(contractsProvider.notifier).refreshContracts(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (contractsState.contracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: AppColors.textGrey),
            const SizedBox(height: 16),
            Text(
              'No contracts found',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(contractsProvider.notifier).refreshContracts(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contractsState.contracts.length,
        itemBuilder: (context, index) {
          final contract = contractsState.contracts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: contract.isActive ? AppColors.primary : AppColors.textGrey,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          contract.contractName,
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          contract.status,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: contract.isActive
                            ? AppColors.success
                            : AppColors.textGrey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contract.customer,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: AppColors.textGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          contract.address,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMetric(
                        'Workers Assigned',
                        contract.workersAssigned.toString(),
                      ),
                      const SizedBox(width: 24),
                      _buildMetric(
                        'Clocked-in Today',
                        contract.clockedInToday.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textGrey,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
