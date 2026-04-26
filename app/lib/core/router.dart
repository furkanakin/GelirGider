import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/accounts/accounts_screen.dart';
import '../features/add/add_picker_screen.dart';
import '../features/add/text_entry_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/family/family_screen.dart';
import '../features/home/home_screen.dart';
import '../features/list/list_screen.dart';
import '../features/monthly/monthly_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/photo/photo_screen.dart';
import '../features/recurring/recurring_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/voice/voice_screen.dart';
import '../features/weekly/weekly_screen.dart';
import '../features/yearly/yearly_screen.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../widgets/app_shell.dart';

GoRouter buildRouter(WidgetRef ref, {bool showOnboarding = false}) {
  return GoRouter(
    initialLocation: showOnboarding ? '/onboarding' : '/home',
    redirect: (ctx, state) {
      final loggedIn = ApiClient.instance.isLoggedIn;
      final path = state.uri.path;
      final isAuthPage = path == '/login' || path == '/forgot' || path == '/onboarding';
      if (!loggedIn && !isAuthPage) return '/login';
      if (loggedIn && (path == '/login' || path == '/onboarding')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),
      ShellRoute(
        builder: (ctx, state, child) {
          final tab = switch (state.matchedLocation) {
            '/home' => 'home',
            '/list' => 'list',
            '/add' => 'add',
            '/monthly' || '/weekly' || '/yearly' || '/categories' => 'chart',
            '/family' => 'people',
            _ => 'home',
          };
          return AppShell(activeTab: tab, child: child);
        },
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/list', builder: (_, __) => const TransactionsListScreen()),
          GoRoute(path: '/add', builder: (_, __) => const AddPickerScreen()),
          GoRoute(path: '/monthly', builder: (_, __) => const MonthlyScreen()),
          GoRoute(path: '/weekly', builder: (_, __) => const WeeklyScreen()),
          GoRoute(path: '/yearly', builder: (_, __) => const YearlyScreen()),
          GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
          GoRoute(path: '/family', builder: (_, __) => const FamilyScreen()),
        ],
      ),
      // Modal-style flows (no shell)
      GoRoute(path: '/voice', builder: (_, __) => const VoiceScreen()),
      GoRoute(path: '/photo', builder: (_, __) => const PhotoScreen()),
      GoRoute(
        path: '/text',
        builder: (_, state) => TextEntryScreen(prefilledCategory: state.extra as Category?),
      ),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/accounts', builder: (_, __) => const AccountsScreen()),
      GoRoute(path: '/recurring', builder: (_, __) => const RecurringScreen()),
    ],
  );
}
