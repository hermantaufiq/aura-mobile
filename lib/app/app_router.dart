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
import '../screens/premium/premium_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnAuth = state.matchedLocation.startsWith('/auth');

      if (isOnSplash) return null;
      if (!isLoggedIn && !isOnAuth) return '/auth/login';
      if (isLoggedIn && isOnAuth) return '/home';
      return null;
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
        builder: (context, state) {
          final extra = state.extra;
          String email = '';
          String password = '';
          if (extra is Map<String, dynamic>) {
            email = extra['email'] as String? ?? '';
            password = extra['password'] as String? ?? '';
          } else if (extra is String) {
            email = extra;
          }
          return OtpScreen(email: email, password: password);
        },
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
});
