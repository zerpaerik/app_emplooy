import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../business/models/location_model.dart';
import '../providers/contracts_provider.dart';
import '../providers/crew_provider.dart';
import '../widgets/crew_sheets_tab.dart';
import '../widgets/workers_tab.dart';
import '../widgets/contracts_tab.dart';

class ContractsListPage extends ConsumerStatefulWidget {
  final Location location;

  const ContractsListPage({
    super.key,
    required this.location,
  });

  @override
  ConsumerState<ContractsListPage> createState() => _ContractsListPageState();
}

class _ContractsListPageState extends ConsumerState<ContractsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    Future.microtask(() {
      ref.read(crewProvider.notifier).fetchCurrentCrew();
      ref.read(crewProvider.notifier).fetchCrewSheets(widget.location.id);
      ref.read(crewProvider.notifier).fetchWorkers(widget.location.id);
      ref.read(contractsProvider.notifier).fetchContracts(widget.location.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    ref.read(crewProvider.notifier).clear();
    ref.read(contractsProvider.notifier).clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crewState = ref.watch(crewProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.location.name,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.location.projectName,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Location Info
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Project: ${widget.location.projectName}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location: ${widget.location.name}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.place, color: AppColors.textGrey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.location.verifiedAddress ?? widget.location.firstAddress,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.textDark,
              unselectedLabelColor: AppColors.textGrey,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              tabs: [
                const Tab(text: 'Crew Sheets'),
                Tab(text: 'Workers (${crewState.workers.length})'),
                const Tab(text: 'Contracts'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                CrewSheetsTab(location: widget.location),
                WorkersTab(location: widget.location),
                ContractsTab(location: widget.location),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
