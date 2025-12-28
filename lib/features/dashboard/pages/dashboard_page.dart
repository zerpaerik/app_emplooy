import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../user/providers/user_provider.dart';
import '../providers/role_provider.dart';
import '../providers/user_modules_provider.dart';
import '../widgets/dashboard_worker.dart';
import '../widgets/dashboard_business.dart';
import '../widgets/profile_completion_banner.dart';
import '../../clockin/pages/clockin_setup_page.dart';
import '../../clockin/pages/clockin_dashboard_page.dart';
import '../../clockin/providers/clockin_provider.dart';
import '../../clockout/pages/clockout_setup_page.dart';
import '../../clockout/providers/clockout_provider.dart';
import '../../workers/pages/workers_list_page.dart';
import '../../workday_reports/pages/workday_reports_list_page.dart';
import '../../workday_reports/pages/workday_report_form_page.dart';
import '../../user/models/user_model.dart';

// Temporary localization class
class _TempLocalizations {
  static const hello = 'Hello';
  static const logout = 'Logout';
  static const notifications = 'Notifications';
  static const settings = 'Settings';
  static const sureLogout = 'Are you sure you want to logout?';
  static const cancel = 'Cancel';
  static const yes = 'Yes';
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Los módulos se cargan desde MainLayoutPage
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await _showLogoutDialog();
    if (shouldLogout == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  // Manejar navegación a Clock-In/Clock-Out según estado del workday
  Future<void> _handleClockInNavigation(BuildContext context, UserModel? user) async {
    if (user == null || user.contract == 0) {
      _showErrorDialog('No contract found for user');
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Inicializar sesión para obtener workday actual
      await ref.read(clockinProvider.notifier).initializeSession(user.contract);
      
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      final clockinState = ref.read(clockinProvider);
      final workday = clockinState.session?.workday;

      // VALIDACIÓN SEGÚN ESTADO DEL WORKDAY:
      
      // 1. Si workday es null -> Start Clock-In
      if (workday == null) {
        print('No workday found -> Start Clock-In');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClockinSetupPage(
              contractId: user.contract,
            ),
          ),
        );
        return;
      }

      // 2. Si clockin no ha sido finalizado -> Dashboard Clock-In
      if (workday.clockInEnd == null) {
        print('Clock-In not finished -> Go to Clock-In Dashboard');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClockinDashboardPage(
              contractId: user.contract,
            ),
          ),
        );
        return;
      }

      // 3. Si clockin finalizado y clockout no abierto -> Start Clock-Out
      if (workday.clockOutStart == null) {
        print('Clock-In finished, Clock-Out not started -> Start Clock-Out');
        await ref.read(clockoutProvider.notifier).initializeSession(user.contract);
        if (!mounted) return;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClockoutSetupPage(
              contractId: user.contract,
            ),
          ),
        );
        return;
      }

      // 4. Si clockout abierto y no finalizado -> Dashboard Clock-Out
      if (workday.clockOutEnd == null) {
        print('Clock-Out started but not finished -> Go to Clock-Out Dashboard');
        await ref.read(clockoutProvider.notifier).initializeSession(user.contract);
        if (!mounted) return;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClockoutSetupPage(
              contractId: user.contract,
            ),
          ),
        );
        return;
      }

      // 5. Si clockout finalizado -> Workday Report
      print('Clock-Out finished -> Go to Workday Report');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkdayReportFormPage(
            workdayId: workday.id!,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        _showErrorDialog('Error: $e');
      }
    }
  }

  // Manejar navegación a Clock-Out (usa la misma lógica que Clock-In)
  Future<void> _handleClockOutNavigation(BuildContext context, UserModel? user) async {
    // Reutilizar la misma lógica de navegación
    await _handleClockInNavigation(context, user);
  }

  // Manejar navegación a Workday Reports con validación de jornada
  Future<void> _handleWorkdayReportsNavigation(BuildContext context, UserModel? user) async {
    if (user == null || user.contract == 0) {
      _showErrorDialog('No contract found for user');
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Inicializar sesión para obtener workday actual
      await ref.read(clockinProvider.notifier).initializeSession(user.contract);
      
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      final clockinState = ref.read(clockinProvider);
      final workday = clockinState.session?.workday;

      // Verificar si hay jornada activa
      if (workday == null) {
        _showErrorDialog('No active workday found');
        return;
      }

      // Verificar si Clock-In y Clock-Out están finalizados
      final clockInFinished = workday.clockInEnd != null;
      final clockOutFinished = workday.clockOutEnd != null;

      if (clockInFinished && clockOutFinished) {
        // Ambos finalizados → Ir directamente al formulario de nuevo reporte
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkdayReportFormPage(
              workdayId: workday.id!,
            ),
          ),
        );
      } else {
        // Jornada en proceso → Mostrar listado de reportes históricos
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WorkdayReportsListPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog('Error: $e');
      }
    }
  }

  Future<bool?> _showSupervisorClockinDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clock-In del Supervisor'),
        content: const Text(
          '¿Deseas hacer tu clock-in antes de comenzar a escanear trabajadores?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Más tarde'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Sí, hacer clock-in'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _TempLocalizations.logout,
          style: AppTextStyles.h2.copyWith(
            color: AppColors.primary,
          ),
        ),
        content: Text(
          _TempLocalizations.sureLogout,
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              _TempLocalizations.cancel,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              _TempLocalizations.yes,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'EMPLOOY',
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '2',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              // TODO: Navegar a notificaciones
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Consumer(
        builder: (context, ref, child) {
          final userState = ref.watch(userProvider);
          final isBusiness = ref.watch(isBusinessProvider);
          final user = userState.user;

          if (userState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh user modules if needed
              await ref.read(userModulesProvider.notifier).refreshModules();
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Banner de perfil incompleto (solo para workers)
                  if (!isBusiness && user != null && !user.hasCompleteProfile)
                    ProfileCompletionBanner(
                      onTap: () {
                        // TODO: Navegar a completar perfil
                      },
                    ),

                  // Header con saludo y avatar
                  _buildUserHeader(),

                  const SizedBox(height: 20),

                  // Dashboard específico según el rol
                  isBusiness
                      ? const DashboardBusiness()
                      : const DashboardWorker(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserHeader() {
    return Consumer(
      builder: (context, ref, child) {
        final userState = ref.watch(userProvider);
        final user = userState.user;
        final firstName = user?.firstName ?? 'User';
        final profileImage = user?.profileImage;

        return Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_TempLocalizations.hello}, $firstName!',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRoleDisplayName(user?.role ?? 'worker'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: profileImage != null && profileImage.isNotEmpty
                    ? NetworkImage(profileImage)
                    : null,
                child: profileImage == null || profileImage.isEmpty
                    ? _buildDefaultAvatar(firstName)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'U',
      style: AppTextStyles.h2.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'business':
        return 'Business Manager';
      case 'supervisor':
        return 'Supervisor';
      case 'worker':
        return 'Worker';
      default:
        return 'User';
    }
  }

  Widget _buildDrawer() {
    return Consumer(
      builder: (context, ref, child) {
        final userState = ref.watch(userProvider);
        final modulesState = ref.watch(userModulesProvider);
        final user = userState.user;
        final modules = modulesState.modules;

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                ),
                accountName: Text(
                  user?.fullName ?? 'User Name',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(
                  user?.email ?? 'user@example.com',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: user?.profileImage != null && user!.profileImage!.isNotEmpty
                      ? NetworkImage(user.profileImage!)
                      : null,
                  child: user?.profileImage == null || user!.profileImage!.isEmpty
                      ? _buildDefaultAvatar(user?.firstName ?? 'U')
                      : null,
                ),
              ),
              // Opciones específicas por rol y módulos
              if (modules != null) ..._buildRoleSpecificOptions(modules, user),
              _buildDrawerItem(
                icon: Icons.notifications,
                title: _TempLocalizations.notifications,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar a notificaciones
                },
              ),
              _buildDrawerItem(
                icon: Icons.settings,
                title: _TempLocalizations.settings,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar a configuración
                },
              ),
              const Divider(),
              _buildDrawerItem(
                icon: Icons.logout,
                title: _TempLocalizations.logout,
                onTap: () {
                  Navigator.pop(context);
                  _handleLogout();
                },
                isDestructive: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.textGrey,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDestructive ? AppColors.error : AppColors.textDark,
        ),
      ),
      onTap: onTap,
    );
  }

  List<Widget> _buildRoleSpecificOptions(modules, user) {
    List<Widget> options = [];

    // Worker: mostrar solo módulos activos del endpoint
    if (modules.role == 'worker') {
      if (modules.clockInModule) {
        options.add(_buildDrawerItem(
          icon: Icons.login,
          title: 'Clock In',
          onTap: () async {
            Navigator.pop(context);
            await _handleClockInNavigation(context, user);
          },
        ));
      }
      
      if (modules.clockOutModule) {
        options.add(_buildDrawerItem(
          icon: Icons.logout,
          title: 'Clock Out',
          onTap: () async {
            Navigator.pop(context);
            await _handleClockOutNavigation(context, user);
          },
        ));
      }
      
      if (modules.expensesModule) {
        options.add(_buildDrawerItem(
          icon: Icons.attach_money,
          title: 'Expenses',
          onTap: () {
            Navigator.pop(context);
            // TODO: Navegar a expenses
          },
        ));
      }
      
      if (modules.warningsModule) {
        options.add(_buildDrawerItem(
          icon: Icons.warning,
          title: 'Warnings',
          onTap: () {
            Navigator.pop(context);
            // TODO: Navegar a warnings
          },
        ));
      }
      
      if (modules.workdayReportsModule) {
        options.add(_buildDrawerItem(
          icon: Icons.assessment,
          title: 'Workday Reports',
          onTap: () async {
            Navigator.pop(context);
            await _handleWorkdayReportsNavigation(context, user);
          },
        ));
      }
    }

    // Supervisor: todos los módulos excepto business
    if (modules.role == 'supervisor' || modules.role == 'is_lead' || modules.role == 'lead') {
      if (modules.clockInModule) {
        options.add(_buildDrawerItem(
          icon: Icons.login,
          title: 'Clock In',
          onTap: () async {
            Navigator.pop(context);
            await _handleClockInNavigation(context, user);
          },
        ));
      }
      
      if (modules.clockOutModule) {
        options.add(_buildDrawerItem(
          icon: Icons.logout,
          title: 'Clock Out',
          onTap: () async {
            Navigator.pop(context);
            await _handleClockOutNavigation(context, user);
          },
        ));
      }
      
      options.add(_buildDrawerItem(
        icon: Icons.people,
        title: 'Workers',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WorkersListPage(),
            ),
          );
        },
      ));
      
      if (modules.expensesModule) {
        options.add(_buildDrawerItem(
          icon: Icons.attach_money,
          title: 'Expenses',
          onTap: () {
            Navigator.pop(context);
            // TODO: Navegar a expenses
          },
        ));
      }
      
      if (modules.warningsModule) {
        options.add(_buildDrawerItem(
          icon: Icons.warning,
          title: 'Warnings',
          onTap: () {
            Navigator.pop(context);
            // TODO: Navegar a warnings
          },
        ));
      }
      
      if (modules.workdayReportsModule) {
        options.add(_buildDrawerItem(
          icon: Icons.assessment,
          title: 'Workday Reports',
          onTap: () async {
            Navigator.pop(context);
            await _handleWorkdayReportsNavigation(context, user);
          },
        ));
      }
    }

    // Business/Customer: proyectos, contratos + módulos activos del endpoint
    if (modules.role == 'business' || modules.role == 'customer' || (user != null && user.locationList.isNotEmpty)) {
      options.add(_buildDrawerItem(
        icon: Icons.business,
        title: 'Projects',
        onTap: () {
          Navigator.pop(context);
          // TODO: Navegar a proyectos
        },
      ));
      
      options.add(_buildDrawerItem(
        icon: Icons.description,
        title: 'Contracts',
        onTap: () {
          Navigator.pop(context);
          // TODO: Navegar a contratos
        },
      ));
      
      // Mostrar módulos activos del endpoint si los tiene
      if (modules.clockInModule) {
        options.add(_buildDrawerItem(
          icon: Icons.login,
          title: 'Clock In',
          onTap: () async {
            Navigator.pop(context);
            await _handleClockInNavigation(context, user);
          },
        ));
      }
      
      if (modules.clockOutModule) {
        options.add(_buildDrawerItem(
          icon: Icons.logout,
          title: 'Clock Out',
          onTap: () async {
            Navigator.pop(context);
            await _handleClockOutNavigation(context, user);
          },
        ));
      }
    }

    if (options.isNotEmpty) {
      options.insert(0, const Divider());
    }

    return options;
  }
}
