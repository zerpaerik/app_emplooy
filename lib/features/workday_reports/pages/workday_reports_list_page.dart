import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../user/providers/user_provider.dart';
import '../../clockin/providers/clockin_provider.dart';
import '../providers/workday_reports_provider.dart';
import '../models/workday_report_model.dart';
import '../widgets/report_card.dart';
import 'workday_report_detail_enhanced_page.dart';

class WorkdayReportsListPage extends ConsumerStatefulWidget {
  const WorkdayReportsListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkdayReportsListPage> createState() => _WorkdayReportsListPageState();
}

class _WorkdayReportsListPageState extends ConsumerState<WorkdayReportsListPage> {
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadReports();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    final user = ref.read(userProvider).user;
    final contractId = user?.contract;
    
    print('🔍 Workday Reports - User: $user');
    print('🔍 Workday Reports - Contract ID: $contractId');
    
    if (contractId != null && contractId > 0) {
      print('✅ Workday Reports - Loading reports for contract: $contractId');
      await ref.read(workdayReportsProvider.notifier).loadReports(contractId);
    } else {
      print('❌ Workday Reports - No valid contract ID found');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(workdayReportsProvider);
    final clockinState = ref.watch(clockinProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Workday Reports',
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Filters',
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(reportsState, clockinState),
    );
  }

  Widget _buildBody(reportsState, clockinState) {
    Widget _buildReportsList(reportsState) {
      if (reportsState.isLoading && reportsState.reports.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (reportsState.error != null) {
        return Center(
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
                'Error loading reports',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reportsState.error!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadReports,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      }

      if (reportsState.reports.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: AppColors.textGrey,
              ),
              const SizedBox(height: 16),
              Text(
                'No reports found',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reports will appear here once created',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        );
      }

      // Aplicar filtros
      final filteredReports = _applyFilters(reportsState.reports);

      if (filteredReports.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.textGrey,
              ),
              const SizedBox(height: 16),
              Text(
                'No reports match filters',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _loadReports,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredReports.length,
          itemBuilder: (context, index) {
            final report = filteredReports[index];
            return ReportCard(
              report: report,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkdayReportDetailEnhancedPage(report: report),
                  ),
                );
              },
              onEdit: () {
                // TODO: Navegar a editar reporte
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit functionality coming soon')),
                );
              },
              onView: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkdayReportDetailEnhancedPage(report: report),
                  ),
                );
              },
              onSend: () {
                // TODO: Implementar envío de reporte
                _showSendDialog(context, report);
              },
            );
          },
        ),
      );
    }

    return Column(
      children: [
        // Filtros expandibles
        if (_showFilters) _buildFiltersSection(),
        
        Expanded(
          child: _buildReportsList(reportsState),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by comments...',
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textGrey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
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
              },
            ),
          ),
          
          // Filtros de fecha y estado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Filtro de estado
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All'),
                      ),
                      const DropdownMenuItem(
                        value: '1',
                        child: Text('Draft'),
                      ),
                      const DropdownMenuItem(
                        value: '2',
                        child: Text('Sent'),
                      ),
                      const DropdownMenuItem(
                        value: '3',
                        child: Text('Approved'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Botón de limpiar filtros
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _filterStartDate = null;
                      _filterEndDate = null;
                      _filterStatus = null;
                    });
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textGrey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey[300]),
        ],
      ),
    );
  }

  List<WorkdayReportModel> _applyFilters(List<WorkdayReportModel> reports) {
    var filtered = reports;

    // Filtrar por búsqueda de texto
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((report) {
        final comments = report.comments?.toLowerCase() ?? '';
        return comments.contains(query);
      }).toList();
    }

    // Filtrar por estado
    if (_filterStatus != null) {
      filtered = filtered.where((report) {
        return report.status == _filterStatus;
      }).toList();
    }

    return filtered;
  }

  void _showSendDialog(BuildContext context, WorkdayReportModel report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: const Text(
          'Send Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        content: const Text(
          'Are you sure you want to send this report?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Implementar lógica de envío
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report sent successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'Send',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
