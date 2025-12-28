import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/workday_report_model.dart';
import '../models/worker_report_model.dart';
import '../providers/worker_report_provider.dart';
import '../widgets/worker_detail_modal.dart';
import '../widgets/worker_list_item.dart';
import '../widgets/edit_worker_dialog.dart';

class WorkdayReportDetailEnhancedPage extends ConsumerStatefulWidget {
  final WorkdayReportModel report;

  const WorkdayReportDetailEnhancedPage({
    Key? key,
    required this.report,
  }) : super(key: key);

  @override
  ConsumerState<WorkdayReportDetailEnhancedPage> createState() =>
      _WorkdayReportDetailEnhancedPageState();
}

class _WorkdayReportDetailEnhancedPageState
    extends ConsumerState<WorkdayReportDetailEnhancedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late WorkerReportParams _params;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _params = WorkerReportParams(
      workdayId: widget.report.workdayId,
      reportId: widget.report.id ?? 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workerReportState = ref.watch(workerReportProvider(_params));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Report Detail',
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) => _handleMenuAction(value, _params),
            itemBuilder: (context) => [
              if (workerReportState.selectedWorkerIds.isNotEmpty)
                const PopupMenuItem(
                  value: 'edit_multiple',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Multiple'),
                    ],
                  ),
                ),
              if (!widget.report.isFinalized)
                const PopupMenuItem(
                  value: 'finalize',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 20),
                      SizedBox(width: 8),
                      Text('Finalize Workday'),
                    ],
                  ),
                ),
              if (workerReportState.canSendReport)
                const PopupMenuItem(
                  value: 'send',
                  child: Row(
                    children: [
                      Icon(Icons.send, size: 20),
                      SizedBox(width: 8),
                      Text('Send Report'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: workerReportState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : workerReportState.error != null
              ? Center(
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          workerReportState.error!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(workerReportProvider(_params).notifier).loadWorkers();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
              children: [
                _buildHeader(workerReportState),
                _buildTabBar(workerReportState),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildWorkerList(
                        workerReportState.workersByCategory[WorkerReportCategory.onTime] ?? [],
                        _params,
                        WorkerReportCategory.onTime,
                      ),
                      _buildWorkerList(
                        workerReportState.workersByCategory[WorkerReportCategory.late] ?? [],
                        _params,
                        WorkerReportCategory.late,
                      ),
                      _buildWorkerList(
                        workerReportState.workersByCategory[WorkerReportCategory.reviewed] ?? [],
                        _params,
                        WorkerReportCategory.reviewed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(WorkerReportState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM dd, yyyy').format(widget.report.reportDate),
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Worked Hours: ${widget.report.workdayTime?.duration ?? 'N/A'}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                '${state.onTimeCount}',
                'On-Time',
                Colors.green,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                '${state.lateCount}',
                'Late',
                Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                '${state.reviewedCount}',
                'Reviewed',
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: AppTextStyles.h4.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final status = widget.report.status;
    Color color;
    String text;

    switch (status) {
      case 'draft':
        color = Colors.grey;
        text = 'Draft';
        break;
      case 'sent':
        color = Colors.green;
        text = 'Sent';
        break;
      case 'approved':
        color = Colors.blue;
        text = 'Approved';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTabBar(WorkerReportState state) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textGrey,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: AppTextStyles.button.copyWith(
          fontWeight: FontWeight.bold,
        ),
        tabs: [
          Tab(
            text: 'On-Time (${state.onTimeCount})',
          ),
          Tab(
            text: 'Late (${state.lateCount})',
          ),
          Tab(
            text: 'Reviewed (${state.reviewedCount})',
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerList(
    List<WorkerReportModel> workers,
    WorkerReportParams params,
    WorkerReportCategory category,
  ) {
    if (workers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textGrey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No workers in this category',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workers.length,
      itemBuilder: (context, index) {
        final worker = workers[index];
        final isSelected = ref
            .watch(workerReportProvider(_params))
            .selectedWorkerIds
            .contains(worker.workerId);

        return WorkerListItem(
          worker: worker,
          isSelected: isSelected,
          onTap: () => _showWorkerDetail(worker),
          onEdit: widget.report.isFinalized
              ? null
              : () => _editWorker(worker, _params),
          onSelectionChanged: widget.report.isFinalized
              ? null
              : (selected) {
                  ref
                      .read(workerReportProvider(_params).notifier)
                      .toggleWorkerSelection(worker.workerId);
                },
        );
      },
    );
  }

  void _showWorkerDetail(WorkerReportModel worker) {
    showDialog(
      context: context,
      builder: (context) => WorkerDetailModal(worker: worker),
    );
  }

  void _editWorker(WorkerReportModel worker, WorkerReportParams params) {
    showDialog(
      context: context,
      builder: (context) => EditWorkerDialog(
        worker: worker,
        params: params,
      ),
    );
  }

  void _handleMenuAction(String action, WorkerReportParams params) async {
    final notifier = ref.read(workerReportProvider(_params).notifier);

    switch (action) {
      case 'edit_multiple':
        // TODO: Implementar edición múltiple
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit multiple workers')),
        );
        break;

      case 'finalize':
        final confirmed = await _showConfirmDialog(
          'Finalize Workday',
          'Are you sure you want to finalize this workday? This action cannot be undone.',
        );

        if (confirmed == true) {
          final success = await notifier.finalizeWorkday();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Workday finalized successfully'
                      : 'Failed to finalize workday',
                ),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        }
        break;

      case 'send':
        final confirmed = await _showConfirmDialog(
          'Send Report',
          'Are you sure you want to send this report?',
        );

        if (confirmed == true) {
          final success = await notifier.sendReport();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Report sent successfully'
                      : 'Failed to send report',
                ),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        }
        break;
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
