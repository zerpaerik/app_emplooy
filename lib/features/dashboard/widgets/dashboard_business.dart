import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

// Temporary localization class
class _TempLocalizations {
  static const activeProjects = 'Active Projects';
  static const totalWorkers = 'Total Workers';
  static const todayClockIns = 'Today Clock-ins';
  static const yesterdayClockIns = 'Yesterday Clock-ins';
  static const todayAbsents = 'Today Absents';
  static const yesterdayAbsents = 'Yesterday Absents';
  static const projectLocations = 'Project Locations';
  static const workersAssigned = 'Workers Assigned';
  static const businessMetrics = 'Business Metrics';
  static const manageProjects = 'Manage Projects';
  static const manageWorkers = 'Manage Workers';
  static const reports = 'Reports';
  static const analytics = 'Analytics';
  static const quickActions = 'Quick Actions';
  static const createProject = 'Create Project';
  static const inviteWorkers = 'Invite Workers';
  static const viewReports = 'View Reports';
  static const settings = 'Settings';
}

class DashboardBusiness extends StatefulWidget {
  const DashboardBusiness({super.key});

  @override
  State<DashboardBusiness> createState() => _DashboardBusinessState();
}

class _DashboardBusinessState extends State<DashboardBusiness> {
  // Datos simulados - en la app real vendrían del servidor
  final Map<String, dynamic> _metricsData = {
    'activeProjects': 5,
    'totalWorkers': 24,
    'todayClockIns': 18,
    'yesterdayClockIns': 22,
    'todayAbsents': 6,
    'yesterdayAbsents': 2,
    'projectLocations': 3,
  };

  final List<Map<String, dynamic>> _projects = [
    {
      'id': 1,
      'name': 'Downtown Office Complex',
      'customer': 'ABC Corp',
      'address': '123 Main St, Downtown',
      'workersAssigned': 8,
      'status': 'active',
      'clockedInToday': 6,
    },
    {
      'id': 2,
      'name': 'Residential Building A',
      'customer': 'XYZ Developers',
      'address': '456 Oak Ave, Suburbs',
      'workersAssigned': 12,
      'status': 'active',
      'clockedInToday': 10,
    },
    {
      'id': 3,
      'name': 'Shopping Center Renovation',
      'customer': 'Retail Group Inc',
      'address': '789 Commerce Blvd',
      'workersAssigned': 4,
      'status': 'active',
      'clockedInToday': 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Metrics Header
          Text(
            _TempLocalizations.businessMetrics,
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Metrics Cards Row 1
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: _TempLocalizations.activeProjects,
                  value: _metricsData['activeProjects'].toString(),
                  icon: Icons.work,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: _TempLocalizations.totalWorkers,
                  value: _metricsData['totalWorkers'].toString(),
                  icon: Icons.people,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metrics Cards Row 2
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: _TempLocalizations.todayClockIns,
                  value: _metricsData['todayClockIns'].toString(),
                  icon: Icons.login,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: _TempLocalizations.todayAbsents,
                  value: _metricsData['todayAbsents'].toString(),
                  icon: Icons.person_off,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Active Projects Section
          Text(
            _TempLocalizations.activeProjects,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Projects List
          ..._projects.map((project) => _buildProjectCard(project)),
          const SizedBox(height: 20),

          // Quick Actions
          Text(
            _TempLocalizations.quickActions,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navegar a detalles del proyecto
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project['name'],
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project['customer'],
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      project['status'].toString().toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: AppColors.textGrey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project['address'],
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
                  _buildProjectStat(
                    icon: Icons.people_outline,
                    label: _TempLocalizations.workersAssigned,
                    value: project['workersAssigned'].toString(),
                  ),
                  const SizedBox(width: 20),
                  _buildProjectStat(
                    icon: Icons.login,
                    label: 'Clocked In Today',
                    value: project['clockedInToday'].toString(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_business,
                label: _TempLocalizations.createProject,
                onTap: () {
                  // TODO: Navegar a crear proyecto
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.person_add,
                label: _TempLocalizations.inviteWorkers,
                onTap: () {
                  // TODO: Navegar a invitar workers
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.assessment,
                label: _TempLocalizations.viewReports,
                onTap: () {
                  // TODO: Navegar a reportes
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.analytics,
                label: _TempLocalizations.analytics,
                onTap: () {
                  // TODO: Navegar a analytics
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
