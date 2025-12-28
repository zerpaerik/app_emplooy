import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../user/providers/user_provider.dart';
import '../../dashboard/providers/user_modules_provider.dart';

// Temporary localization class
class _TempLocalizations {
  static const profile = 'Profile';
  static const personalInformation = 'Personal Information';
  static const academicInformation = 'Academic Information';
  static const jobOffers = 'Job Offers';
  static const certifications = 'Certifications';
  static const warnings = 'Warnings';
  static const taxes = 'Taxes';
  static const settings = 'Settings';
  static const referralProgram = 'Referral Program';
  static const shareReferralCode = 'Share your referral code and earn rewards!';
  static const employeeId = 'Employee ID';
}

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    // Los módulos se cargan desde MainLayoutPage
    // Solo simular carga para mostrar el loading state
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final modulesState = ref.watch(userModulesProvider);
    final user = userState.user;
    final modules = modulesState.modules;

    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header con gradiente y avatar
              _buildProfileHeader(user),
              
              // Información del usuario
              _buildUserInfo(user),
              
              // Botones de acceso rápido
              _buildQuickAccessButtons(),
              
              // Botón de referidos
              _buildReferralButton(),
              
              const SizedBox(height: 20),
              
              // Lista de opciones del perfil
              _buildProfileOptions(modules),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 2,
      backgroundColor: Colors.white,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.primary),
      title: Text(
        _TempLocalizations.profile,
        style: AppTextStyles.h2.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildProfileHeader(user) {
    return Stack(
      children: [
        // Fondo con gradiente
        Container(
          height: 150,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        
        // Avatar centrado
        Positioned(
          top: 75,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                // TODO: Cambiar foto de perfil
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildProfileImage(user),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage(user) {
    final profileImage = user?.profileImage;
    
    if (profileImage != null && profileImage.isNotEmpty) {
      return Image.network(
        profileImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar(user);
        },
      );
    }
    
    return _buildDefaultAvatar(user);
  }

  Widget _buildDefaultAvatar(user) {
    final firstName = user?.firstName ?? 'U';
    
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          firstName[0].toUpperCase(),
          style: AppTextStyles.h1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(user) {
    final email = user?.email ?? '';
    final employeeId = user?.btnId ?? '';
    final role = user?.role ?? 'worker';

    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            user?.fullName ?? 'User Name',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRoleDisplayName(role),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (employeeId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${_TempLocalizations.employeeId}: $employeeId',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAccessButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickButton(
              icon: Icons.verified_user,
              label: _TempLocalizations.certifications,
              onTap: () {
                // TODO: Navegar a certificaciones
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickButton(
              icon: Icons.warning_outlined,
              label: _TempLocalizations.warnings,
              onTap: () {
                // TODO: Navegar a amonestaciones
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickButton(
              icon: Icons.receipt_long,
              label: _TempLocalizations.taxes,
              onTap: () {
                // TODO: Navegar a impuestos
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralButton() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            // TODO: Compartir código de referido
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.share,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _TempLocalizations.referralProgram,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _TempLocalizations.shareReferralCode,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOptions(modules) {
    return Column(
      children: [
        // Opciones para workers (no business)
        if (modules?.role != 'business' && modules?.role != 'customer') ...[
          _buildProfileOption(
            icon: Icons.person,
            title: _TempLocalizations.personalInformation,
            onTap: () {
              // TODO: Navegar a información personal
            },
          ),
          _buildProfileOption(
            icon: Icons.school,
            title: _TempLocalizations.academicInformation,
            onTap: () {
              // TODO: Navegar a información académica
            },
          ),
          _buildProfileOption(
            icon: Icons.work_outline,
            title: _TempLocalizations.jobOffers,
            onTap: () {
              // TODO: Navegar a ofertas de trabajo
            },
          ),
        ],
        
        // Configuración - Siempre visible
        _buildProfileOption(
          icon: Icons.settings,
          title: _TempLocalizations.settings,
          onTap: () {
            // TODO: Navegar a configuración
          },
        ),
      ],
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: AppColors.primary,
          ),
          title: Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textGrey,
            size: 16,
          ),
          onTap: onTap,
        ),
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
}
