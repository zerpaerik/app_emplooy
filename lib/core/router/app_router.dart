import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/language/pages/language_selection_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/auth/pages/recover_password_page.dart';
import '../../features/main/pages/main_layout_page.dart';
import '../storage/local_storage.dart';

/// Configuración del router de la aplicación
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final storage = LocalStorage.instance;
      final isFirstTime = storage.isFirstTime();
      final isLoggedIn = storage.isLoggedIn();
      final token = storage.getAuthToken();

      // Si es primera vez, ir a selección de idioma
      if (isFirstTime && state.matchedLocation != '/language') {
        return '/language';
      }

      // Si dice que está logueado pero no hay token, limpiar datos y redirigir a login
      if (isLoggedIn && token == null) {
        await storage.clearSession();
        return '/login';
      }

      // Si no está logueado y no va a login o language, redirigir a login
      if (!isLoggedIn &&
          state.matchedLocation != '/login' &&
          state.matchedLocation != '/language' &&
          !state.matchedLocation.startsWith('/register') &&
          !state.matchedLocation.startsWith('/recover-password')) {
        return '/login';
      }

      // Si está logueado y va a login o language, redirigir a dashboard
      if (isLoggedIn &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/language')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/login',
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageSelectionPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/recover-password',
        builder: (context, state) => const RecoverPasswordPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainLayoutPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
}
