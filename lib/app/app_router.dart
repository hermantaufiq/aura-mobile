import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/dashboard/main_shell.dart';
import '../screens/dashboard/home_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../screens/tasks/task_form_screen.dart';
import '../screens/finance/finance_screen.dart';
import '../screens/finance/finance_form_screen.dart';
import '../screens/ai/ai_chat_screen.dart';
import '../screens/ai/ai_insight_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/premium/premium_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _adminShellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  // ── FIX: Buat router SEKALI, pakai refresh() saat auth berubah ──────────
  // Jangan ref.watch di sini! Setiap kali auth state berubah, router lama
  // dibuang dan GoRouter baru dibuat → navigasi ke /auth/otp hilang.

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isLoggedIn;
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnAuth = state.matchedLocation.startsWith('/auth');
      final isOnOtp = state.matchedLocation == '/auth/otp';
      final isOnAdminAuth = state.matchedLocation == '/admin/login';
      final isOnAdminApp = state.matchedLocation.startsWith('/admin') && !isOnAdminAuth;
      final role = authState.user?.role;

      // OTP screen: prevent redirect away while user is in the middle of registration.
      // But if they are logged in (OTP verified), let them flow to the authenticated redirects.
      if (isOnOtp && !isLoggedIn) return null;

      // Still loading auth (initial app startup only, indicated by being on splash)
      // Do NOT redirect to splash during register/login isLoading — that would
      // interrupt in-progress flows like the OTP navigation.
      if (authState.isLoading && isOnSplash) return null;

      // Splash screen: don't interfere (SplashScreen handles nav itself)
      if (isOnSplash) return null;

      // Handle unauthenticated users
      if (!isLoggedIn) {
        if (isOnAdminAuth) return null;
        if (isOnAdminApp) return '/admin/login';
        if (!isOnAuth) return '/auth/login';
        return null;
      }

      // Handle authenticated users
      if (role == 'admin') {
        if (isOnAuth || isOnAdminAuth) return '/admin/dashboard';
        // If admin is on non-admin, non-splash page — redirect to admin dashboard
        if (!isOnAdminApp) return '/admin/dashboard';
        return null;
      } else {
        // If a normal user explicitly visits /admin/login, let them see it so they can login as admin!
        if (isOnAdminAuth) return null;

        if (isOnAdminApp) return '/auth/login';
        if (isOnAuth) return '/home';
        return null;
      }
    },
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        name: 'otp',
        builder: (context, state) => const OtpScreen(),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin/login',
        name: 'admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),

      // Admin Shell
      ShellRoute(
        navigatorKey: _adminShellNavigatorKey,
        builder: (context, state, child) {
          return AdminShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            name: 'admin-dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            name: 'admin-users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            name: 'admin-settings',
            builder: (context, state) => const AdminSettingsScreen(),
          ),
        ],
      ),

      // Main Shell with Bottom Navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            builder: (context, state) => const TasksScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'task-add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const TaskFormScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                name: 'task-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final taskId = state.pathParameters['id']!;
                  return TaskFormScreen(taskId: taskId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/finance',
            name: 'finance',
            builder: (context, state) => const FinanceScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'finance-add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const FinanceFormScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                name: 'finance-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final financeId = state.pathParameters['id']!;
                  return FinanceFormScreen(financeId: financeId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/ai',
            name: 'ai',
            builder: (context, state) => const AiChatScreen(),
            routes: [
              GoRoute(
                path: 'insight',
                name: 'ai-insight',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AiInsightScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'profile-edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const EditProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Premium (outside shell)
      GoRoute(
        path: '/premium',
        name: 'premium',
        builder: (context, state) => const PremiumScreen(),
      ),

      // Notifications (outside shell)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Halaman tidak ditemukan\n${state.error}',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );

  // Refresh router redirect setiap kali auth state berubah
  ref.listen(authStateProvider, (_, __) => router.refresh());

  return router;
});
