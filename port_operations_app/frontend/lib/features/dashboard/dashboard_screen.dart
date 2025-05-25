import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/user_model.dart';
import '../auth/auth_service.dart';
import '../../shared/widgets/app_drawer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${user.roleDisplayName} Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Refresh dashboard data
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement refresh logic
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context, user),
              const SizedBox(height: 16),
              _buildQuickStats(context, user),
              const SizedBox(height: 16),
              _buildQuickActions(context, user),
              const SizedBox(height: 16),
              _buildRecentActivity(context, user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, User user) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.white.withOpacity(0.2),
                  child: Text(
                    user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        user.fullName.isNotEmpty ? user.fullName : user.username,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.roleDisplayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getWelcomeMessage(user.role),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, User user) {
    final stats = _getQuickStats(user.role);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          stat['icon'] as IconData,
                          color: stat['color'] as Color,
                          size: 24,
                        ),
                        Text(
                          stat['value'] as String,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: stat['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      stat['title'] as String,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, User user) {
    final actions = _getQuickActions(context, user.role);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return Card(
              child: InkWell(
                onTap: action['onTap'] as VoidCallback,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          action['title'] as String,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.history,
                  size: 48,
                  color: AppColors.grey400,
                ),
                const SizedBox(height: 12),
                Text(
                  'No recent activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your recent actions will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getWelcomeMessage(String role) {
    switch (role) {
      case 'admin':
        return 'You have full system access. Monitor operations and manage users.';
      case 'manager':
        return 'Manage operations, approve expenses, and oversee daily activities.';
      case 'supervisor':
        return 'Track equipment, manage field operations, and submit expenses.';
      case 'accountant':
        return 'Handle financial approvals, manage wallets, and log entries to Tally.';
      default:
        return 'Welcome to the Port Operations Management System.';
    }
  }

  List<Map<String, dynamic>> _getQuickStats(String role) {
    switch (role) {
      case 'admin':
        return [
          {
            'title': 'Total Operations',
            'value': '0',
            'icon': MdiIcons.shipWheel,
            'color': AppColors.primary,
          },
          {
            'title': 'Active Users',
            'value': '0',
            'icon': Icons.people,
            'color': AppColors.secondary,
          },
          {
            'title': 'Running Equipment',
            'value': '0',
            'icon': MdiIcons.crane,
            'color': AppColors.warning,
          },
          {
            'title': 'Total Revenue',
            'value': '₹0',
            'icon': Icons.currency_rupee,
            'color': AppColors.success,
          },
        ];
      case 'manager':
        return [
          {
            'title': 'My Operations',
            'value': '0',
            'icon': MdiIcons.shipWheel,
            'color': AppColors.primary,
          },
          {
            'title': 'Pending Approvals',
            'value': '0',
            'icon': Icons.approval,
            'color': AppColors.warning,
          },
          {
            'title': 'Running Equipment',
            'value': '0',
            'icon': MdiIcons.crane,
            'color': AppColors.secondary,
          },
          {
            'title': 'Today\'s Entries',
            'value': '0',
            'icon': Icons.today,
            'color': AppColors.info,
          },
        ];
      case 'supervisor':
        return [
          {
            'title': 'Wallet Balance',
            'value': '₹0',
            'icon': Icons.account_balance_wallet,
            'color': AppColors.success,
          },
          {
            'title': 'Running Equipment',
            'value': '0',
            'icon': MdiIcons.crane,
            'color': AppColors.warning,
          },
          {
            'title': 'Today\'s Equipment',
            'value': '0',
            'icon': Icons.today,
            'color': AppColors.primary,
          },
          {
            'title': 'Pending Expenses',
            'value': '0',
            'icon': Icons.receipt,
            'color': AppColors.error,
          },
        ];
      case 'accountant':
        return [
          {
            'title': 'Pending Expenses',
            'value': '0',
            'icon': Icons.receipt_long,
            'color': AppColors.warning,
          },
          {
            'title': 'Pending Vouchers',
            'value': '0',
            'icon': Icons.description,
            'color': AppColors.error,
          },
          {
            'title': 'Total Revenue',
            'value': '₹0',
            'icon': Icons.currency_rupee,
            'color': AppColors.success,
          },
          {
            'title': 'Tally Logs',
            'value': '0',
            'icon': MdiIcons.fileDocumentOutline,
            'color': AppColors.primary,
          },
        ];
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _getQuickActions(BuildContext context, String role) {
    switch (role) {
      case 'admin':
        return [
          {
            'title': 'Manage Users',
            'icon': Icons.people,
            'color': AppColors.primary,
            'onTap': () {
              context.go('/users');
            },
          },
          {
            'title': 'View Operations',
            'icon': MdiIcons.shipWheel,
            'color': AppColors.secondary,
            'onTap': () {
              context.go('/operations');
            },
          },
          {
            'title': 'System Settings',
            'icon': Icons.settings,
            'color': AppColors.accent,
            'onTap': () {
              context.go('/settings');
            },
          },
          {
            'title': 'Reports',
            'icon': Icons.analytics,
            'color': AppColors.success,
            'onTap': () {
              context.go('/reports');
            },
          },
        ];
      case 'manager':
        return [
          {
            'title': 'New Operation',
            'icon': Icons.add_circle,
            'color': AppColors.primary,
            'onTap': () {
              context.go('/operations/new');
            },
          },
          {
            'title': 'View Equipment',
            'icon': MdiIcons.crane,
            'color': AppColors.secondary,
            'onTap': () {
              context.go('/equipment');
            },
          },
          {
            'title': 'Rate Master',
            'icon': Icons.monetization_on,
            'color': AppColors.accent,
            'onTap': () {
              context.go('/rates');
            },
          },
          {
            'title': 'Expense Approvals',
            'icon': Icons.approval,
            'color': AppColors.warning,
            'onTap': () {
              context.go('/expenses/approvals');
            },
          },
        ];
      case 'supervisor':
        return [
          {
            'title': 'Start Equipment',
            'icon': Icons.play_circle,
            'color': AppColors.success,
            'onTap': () {
              context.push('/equipment/start');
            },
          },
          {
            'title': 'View Wallet',
            'icon': Icons.account_balance_wallet,
            'color': AppColors.primary,
            'onTap': () {
              context.go('/wallet');
            },
          },
          {
            'title': 'Submit Expense',
            'icon': Icons.receipt_long,
            'color': AppColors.warning,
            'onTap': () {
              context.go('/expenses/new');
            },
          },
          {
            'title': 'Digital Voucher',
            'icon': Icons.camera_alt,
            'color': AppColors.secondary,
            'onTap': () {
              context.go('/vouchers/new');
            },
          },
        ];
      case 'accountant':
        return [
          {
            'title': 'Approve Expenses',
            'icon': Icons.check_circle,
            'color': AppColors.success,
            'onTap': () {
              context.go('/expenses');
            },
          },
          {
            'title': 'Wallet Top-up',
            'icon': Icons.add_card,
            'color': AppColors.primary,
            'onTap': () {
              context.go('/wallet/topup');
            },
          },
          {
            'title': 'Revenue Entry',
            'icon': Icons.currency_rupee,
            'color': AppColors.accent,
            'onTap': () {
              context.go('/revenue/new');
            },
          },
          {
            'title': 'Tally Logs',
            'icon': MdiIcons.fileDocumentOutline,
            'color': AppColors.secondary,
            'onTap': () {
              context.go('/tally');
            },
          },
        ];
      default:
        return [];
    }
  }
} 