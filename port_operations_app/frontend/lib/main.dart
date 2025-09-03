import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/operations/operations_screen.dart';
import 'features/operations/create_operation_screen.dart';
import 'features/operations/edit_operation_screen.dart';
import 'features/equipment/equipment_screen.dart';
import 'features/equipment/screens/start_equipment_screen.dart';
import 'features/equipment/screens/end_equipment_screen.dart';
import 'features/equipment/screens/equipment_history_screen.dart';
import 'features/equipment/screens/equipment_detail_screen.dart';
import 'features/equipment/screens/equipment_edit_screen.dart';

import 'features/wallet/wallet_screen.dart';
import 'features/users/users_screen.dart';
import 'features/labour/screens/labour_cost_list_screen.dart';
import 'features/labour/screens/labour_cost_form_screen.dart';
import 'features/labour/screens/labour_cost_detail_screen.dart';
import 'features/rate_master/screens/rate_master_list_screen.dart';
import 'features/equipment/screens/equipment_rate_master_list_screen.dart';
import 'features/transport/screens/transport_list_screen.dart';
import 'features/transport/screens/transport_form_screen.dart';
import 'features/transport/screens/transport_detail_screen.dart';
import 'features/miscellaneous/screens/miscellaneous_list_screen.dart';
import 'features/miscellaneous/screens/miscellaneous_form_screen.dart';
import 'features/miscellaneous/screens/miscellaneous_detail_screen.dart';

import 'features/wallet/screens/expense_approvals_screen.dart';
import 'features/wallet/screens/voucher_approvals_screen.dart';
import 'features/wallet/screens/wallet_management_screen.dart';
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

// Global key for restarting the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
        final user = authState.user;

        print('🛣️ Router redirect: path=${state.matchedLocation}, isLoggedIn=$isLoggedIn, isLoading=$isLoading, user=${user?.username ?? 'null'}');

        // If still loading, don't redirect
        if (isLoading) {
          print('🛣️ Router redirect: Still loading, no redirect');
          return null;
        }

        // If going to login page
        if (state.matchedLocation == '/login') {
          // If already logged in, redirect to dashboard
          if (isLoggedIn && user != null) {
            print('🛣️ Router redirect: Already logged in, redirecting to dashboard');
            return '/dashboard';
          }
          // Otherwise stay on login page
          print('🛣️ Router redirect: Not logged in, staying on login page');
          return null;
        }

        // For all other pages, check if logged in
        if (!isLoggedIn || user == null) {
          print('🛣️ Router redirect: Not logged in or no user, redirecting to login');
          return '/login';
        }

        // No redirect needed
        print('🛣️ Router redirect: Authenticated user accessing ${state.matchedLocation}, no redirect needed');
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
        // TODO: Add more routes for operations, etc.
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
          path: '/operations/:id/edit',
          name: 'operations-edit',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return EditOperationScreen(operationId: id);
          },
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
          path: '/equipment/:id/detail',
          name: 'equipment-detail',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return EquipmentDetailScreen(equipmentId: id);
          },
        ),
        GoRoute(
          path: '/equipment/:id/edit',
          name: 'equipment-edit',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return EquipmentEditScreen(equipmentId: id);
          },
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
          path: '/wallet-management',
          name: 'wallet-management',
          builder: (context, state) => const WalletManagementScreen(),
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
          path: '/approvals',
          name: 'approvals',
          builder: (context, state) => const ExpenseApprovalsScreen(),
        ),
        GoRoute(
          path: '/voucher-approvals',
          name: 'voucher-approvals',
          builder: (context, state) => const VoucherApprovalsScreen(),
        ),
        GoRoute(
          path: '/expenses/approvals',
          name: 'expenses-approvals',
          builder: (context, state) => const ExpenseApprovalsScreen(),
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
          builder: (context, state) => const TransportListScreen(),
        ),
        GoRoute(
          path: '/transport/add',
          name: 'transport-add',
          builder: (context, state) => const TransportFormScreen(),
        ),
        GoRoute(
          path: '/transport/:id/detail',
          name: 'transport-detail',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return TransportDetailScreen(transportId: id);
          },
        ),
        GoRoute(
          path: '/transport/:id/edit',
          name: 'transport-edit',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return TransportFormScreen(transportId: id);
          },
        ),
        // Miscellaneous Cost Routes
        GoRoute(
          path: '/miscellaneous',
          name: 'miscellaneous',
          builder: (context, state) => const MiscellaneousListScreen(),
        ),
        GoRoute(
          path: '/miscellaneous/add',
          name: 'miscellaneous-add',
          builder: (context, state) => const MiscellaneousFormScreen(),
        ),
        GoRoute(
          path: '/miscellaneous/:id/detail',
          name: 'miscellaneous-detail',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return MiscellaneousDetailScreen(costId: id);
          },
        ),
        GoRoute(
          path: '/miscellaneous/:id/edit',
          name: 'miscellaneous-edit',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return MiscellaneousFormScreen(costId: id);
          },
        ),
        GoRoute(
          path: '/rates',
          name: 'rates',
          builder: (context, state) => const RateMasterListScreen(),
        ),
        GoRoute(
          path: '/equipment-rates',
          name: 'equipment-rates',
          builder: (context, state) => const EquipmentRateMasterListScreen(),
        ),

        GoRoute(
          path: '/tally',
          name: 'tally',
          builder: (context, state) => const _PlaceholderScreen(title: 'Tally Integration'),
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
        // Labour Cost Routes
        GoRoute(
          path: '/labour',
          name: 'labour',
          builder: (context, state) => const LabourCostListScreen(),
        ),
        GoRoute(
          path: '/labour/new',
          name: 'labour-new',
          builder: (context, state) {
            final operationId = state.extra as int?;
            return LabourCostFormScreen(operationId: operationId);
          },
        ),
        GoRoute(
          path: '/labour/:id',
          name: 'labour-detail',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return LabourCostDetailScreen(labourCostId: id);
          },
        ),
        GoRoute(
          path: '/labour/:id/edit',
          name: 'labour-edit',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return LabourCostFormScreen(labourCostId: id);
          },
        ),
        GoRoute(
          path: '/operations/:operationId/labour',
          name: 'operation-labour',
          builder: (context, state) {
            final operationId = int.parse(state.pathParameters['operationId']!);
            return LabourCostListScreen(operationId: operationId);
          },
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
      final prevLoggedIn = previous?.isLoggedIn ?? false;
      final nextLoggedIn = next.isLoggedIn;
      final prevUser = previous?.user?.username ?? 'null';
      final nextUser = next.user?.username ?? 'null';
      
      print('🔄 Router refresh: Auth state changed:');
      print('   isLoggedIn: $prevLoggedIn -> $nextLoggedIn');
      print('   user: $prevUser -> $nextUser');
      print('   isLoading: ${previous?.isLoading ?? false} -> ${next.isLoading}');
      
      // Notify router when auth state changes significantly
      if (prevLoggedIn != nextLoggedIn || prevUser != nextUser) {
        print('🔄 Router refresh: Significant change detected, notifying listeners');
        notifyListeners();
      } else {
        print('🔄 Router refresh: No significant change, not notifying');
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
