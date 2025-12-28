import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../user/providers/user_provider.dart';
import '../providers/workers_provider.dart';
import '../widgets/worker_card.dart';
import 'worker_detail_page.dart';

class WorkersListPage extends ConsumerStatefulWidget {
  const WorkersListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkersListPage> createState() => _WorkersListPageState();
}

class _WorkersListPageState extends ConsumerState<WorkersListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar workers al iniciar
    Future.microtask(() {
      final user = ref.read(userProvider).user;
      print('🔍 Workers - User: $user');
      print('🔍 Workers - Contract ID: ${user?.contract}');
      if (user != null && user.contract > 0) {
        print('✅ Workers - Loading workers for contract: ${user.contract}');
        ref.read(workersProvider.notifier).loadWorkers(user.contract);
      } else {
        print('❌ Workers - No valid contract ID found');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workersState = ref.watch(workersProvider);
    final user = ref.watch(userProvider).user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Workers',
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
      body: Column(
        children: [
          // Campo de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                ),
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textGrey),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(workersProvider.notifier).clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderMedium),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                ref.read(workersProvider.notifier).searchWorkers(value);
              },
            ),
          ),

          // Lista de workers
          Expanded(
            child: _buildWorkersList(workersState, user),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkersList(WorkersState workersState, user) {
    // Loading state
    if (workersState.isLoading && workersState.workers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (workersState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading workers',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                workersState.error!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (user != null && user.contract > 0) {
                    ref.read(workersProvider.notifier).loadWorkers(user.contract);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (workersState.filteredWorkers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                workersState.searchQuery.isEmpty
                    ? Icons.people_outline
                    : Icons.search_off,
                size: 64,
                color: AppColors.textGrey,
              ),
              const SizedBox(height: 16),
              Text(
                workersState.searchQuery.isEmpty
                    ? 'No workers found'
                    : 'No results found',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                workersState.searchQuery.isEmpty
                    ? 'There are no workers in this contract'
                    : 'Try searching with a different term',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Lista con workers
    return RefreshIndicator(
      onRefresh: () async {
        if (user != null && user.contract > 0) {
          await ref.read(workersProvider.notifier).refreshWorkers(user.contract);
        }
      },
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: workersState.filteredWorkers.length,
        itemBuilder: (context, index) {
          final worker = workersState.filteredWorkers[index];
          return WorkerCard(
            worker: worker,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkerDetailPage(worker: worker),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
