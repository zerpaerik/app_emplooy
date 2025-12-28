import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/local_storage.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_colors.dart';
import 'features/language/providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar almacenamiento local
  await LocalStorage.instance.init();

  runApp(
    const ProviderScope(
      child: EmplooyApp(),
    ),
  );
}

class EmplooyApp extends ConsumerWidget {
  const EmplooyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'Emplooy',
      debugShowCheckedModeBanner: false,

      // Router Configuration
      routerConfig: AppRouter.router,

      // Localization (temporarily disabled)
      locale: locale,

      // Theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.backgroundWhite,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.primary),
        ),
      ),
    );
  }
}
