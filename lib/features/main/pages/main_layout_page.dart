import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../dashboard/pages/dashboard_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../dashboard/providers/user_modules_provider.dart';
import '../../qr/pages/qr_page.dart';

// Temporary localization class
class _TempLocalizations {
  static const home = 'Home';
  static const qrCode = 'QR Code';
  static const profile = 'Profile';
}

class MainLayoutPage extends ConsumerStatefulWidget {
  const MainLayoutPage({super.key});

  @override
  ConsumerState<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends ConsumerState<MainLayoutPage> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const DashboardPage(),
    const QRPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Cargar módulos del usuario usando Future.microtask para evitar errores de build
    Future.microtask(() {
      if (mounted) {
        ref.read(userModulesProvider.notifier).fetchUserModules();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGrey,
        selectedLabelStyle: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.bodySmall,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 0 ? Icons.home : Icons.home_outlined,
              size: 24,
            ),
            label: _TempLocalizations.home,
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == 1 
                    ? AppColors.primary 
                    : AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.qr_code,
                size: 28,
                color: _currentIndex == 1 
                    ? Colors.white 
                    : AppColors.primary,
              ),
            ),
            label: _TempLocalizations.qrCode,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 2 ? Icons.person : Icons.person_outline,
              size: 24,
            ),
            label: _TempLocalizations.profile,
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

