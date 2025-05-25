import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/operations/operations_screen.dart';
import 'features/operations/create_operation_screen.dart';
import 'features/equipment/equipment_screen.dart';
import 'features/equipment/screens/start_equipment_screen.dart';
import 'features/equipment/screens/end_equipment_screen.dart';
import 'features/equipment/screens/equipment_history_screen.dart';
import 'features/financial/financial_screen.dart';
import 'features/wallet/wallet_screen.dart';
import 'features/users/users_screen.dart';
import 'features/auth/auth_service.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_constants.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PortOperationsApp(),
    ),
  );
}

class PortOperationsApp extends ConsumerWidget {
  const PortOperationsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _createRouter(ref);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  GoRouter _createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final authState = ref.read(authStateProvider);
        final isLoggedIn = authState.isLoggedIn;
        final isLoading = authState.isLoading;

        // If still loading, don't redirect
        if (isLoading) return null;

        // If going to login page
        if (state.matchedLocation == '/login') {
          // If already logged in, redirect to dashboard
          if (isLoggedIn) return '/dashboard';
          // Otherwise stay on login page
          return null;
        }

        // For all other pages, check if logged in
        if (!isLoggedIn) return '/login';

        // No redirect needed
        return null;
      },
      refreshListenable: _RouterRefreshNotifier(ref),
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        // TODO: Add more routes for operations, financial modules, etc.
        GoRoute(
          path: '/operations',
          name: 'operations',
          builder: (context, state) => const OperationsScreen(),
        ),
        GoRoute(
          path: '/operations/new',
          name: 'operations-new',
          builder: (context, state) => const CreateOperationScreen(),
        ),
        GoRoute(
          path: '/equipment',
          name: 'equipment',
          builder: (context, state) => const EquipmentScreen(),
        ),
        GoRoute(
          path: '/equipment/start',
          name: 'equipment-start',
          builder: (context, state) => const StartEquipmentScreen(),
        ),
        GoRoute(
          path: '/equipment/end',
          name: 'equipment-end',
          builder: (context, state) => const EndEquipmentScreen(),
        ),
        GoRoute(
          path: '/equipment/history',
          name: 'equipment-history',
          builder: (context, state) => const EquipmentHistoryScreen(),
        ),
        GoRoute(
          path: '/financial',
          name: 'financial',
          builder: (context, state) => const FinancialScreen(),
        ),
        GoRoute(
          path: '/wallet',
          name: 'wallet',
          builder: (context, state) => const WalletScreen(),
        ),
        GoRoute(
          path: '/wallet/topup',
          name: 'wallet-topup',
          builder: (context, state) => const _PlaceholderScreen(title: 'Wallet Top-up'),
        ),
        GoRoute(
          path: '/expenses',
          name: 'expenses',
          builder: (context, state) => const _PlaceholderScreen(title: 'Expenses'),
        ),
        GoRoute(
          path: '/expenses/new',
          name: 'expenses-new',
          builder: (context, state) => const _PlaceholderScreen(title: 'Submit Expense'),
        ),
        GoRoute(
          path: '/expenses/approvals',
          name: 'expenses-approvals',
          builder: (context, state) => const _PlaceholderScreen(title: 'Expense Approvals'),
        ),
        GoRoute(
          path: '/vouchers',
          name: 'vouchers',
          builder: (context, state) => const _PlaceholderScreen(title: 'Digital Vouchers'),
        ),
        GoRoute(
          path: '/vouchers/new',
          name: 'vouchers-new',
          builder: (context, state) => const _PlaceholderScreen(title: 'New Digital Voucher'),
        ),
        GoRoute(
          path: '/users',
          name: 'users',
          builder: (context, state) => const UsersScreen(),
        ),
        GoRoute(
          path: '/transport',
          name: 'transport',
          builder: (context, state) => const _PlaceholderScreen(title: 'Transport & Labour'),
        ),
        GoRoute(
          path: '/rates',
          name: 'rates',
          builder: (context, state) => const _PlaceholderScreen(title: 'Rate Master'),
        ),
        GoRoute(
          path: '/revenue',
          name: 'revenue',
          builder: (context, state) => const _PlaceholderScreen(title: 'Revenue Streams'),
        ),
        GoRoute(
          path: '/revenue/new',
          name: 'revenue-new',
          builder: (context, state) => const _PlaceholderScreen(title: 'Revenue Entry'),
        ),
        GoRoute(
          path: '/tally',
          name: 'tally',
          builder: (context, state) => const _PlaceholderScreen(title: 'Tally Integration'),
        ),
        GoRoute(
          path: '/reports',
          name: 'reports',
          builder: (context, state) => const _PlaceholderScreen(title: 'Reports'),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const _PlaceholderScreen(title: 'Profile'),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const _PlaceholderScreen(title: 'Settings'),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Router refresh notifier to listen to auth state changes
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _ref.listen<AuthState>(authStateProvider, (previous, next) {
      // Notify router when auth state changes
      if (previous?.isLoggedIn != next.isLoggedIn) {
        notifyListeners();
      }
    });
  }

  final WidgetRef _ref;
}

// Placeholder screen for routes that are not implemented yet
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '$title module is under development',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
