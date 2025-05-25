import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/auth_service.dart';
import '../models/user_model.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) {
      return const Drawer(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Drawer(
      child: Column(
        children: [
          _buildUserHeader(context, user, ref),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavigationItems(context, user),
                const Divider(),
                _buildAccountItems(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, User user, WidgetRef ref) {
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: AppColors.white,
        child: Text(
          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      accountName: Text(
        user.fullName.isNotEmpty ? user.fullName : user.username,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      accountEmail: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.email,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.roleDisplayName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems(BuildContext context, User user) {
    final items = _getNavigationItems(context, user.role);
    
    return Column(
      children: items.map((item) {
        return ListTile(
          leading: Icon(
            item['icon'] as IconData,
            color: item['color'] as Color,
          ),
          title: Text(item['title'] as String),
          onTap: item['onTap'] as VoidCallback,
          trailing: item['badge'] != null 
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item['badge'] as String,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildAccountItems(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person, color: AppColors.textSecondary),
          title: const Text('Profile'),
          onTap: () {
            Navigator.pop(context);
            context.go('/profile');
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings, color: AppColors.textSecondary),
          title: const Text('Settings'),
          onTap: () {
            Navigator.pop(context);
            context.go('/settings');
          },
        ),
        ListTile(
          leading: const Icon(Icons.help, color: AppColors.textSecondary),
          title: const Text('Help & Support'),
          onTap: () {
            Navigator.pop(context);
            // TODO: Navigate to help
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: const Text('Logout'),
          textColor: AppColors.error,
          onTap: () async {
            Navigator.pop(context);
            await _showLogoutConfirmation(context, ref);
          },
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getNavigationItems(BuildContext context, String role) {
    final baseItems = [
      {
        'title': 'Dashboard',
        'icon': Icons.dashboard,
        'color': AppColors.primary,
        'onTap': () {
          Navigator.pop(context);
          context.go('/dashboard');
        },
      },
    ];

    switch (role) {
      case 'admin':
        return [
          ...baseItems,
          {
            'title': 'User Management',
            'icon': Icons.people,
            'color': AppColors.adminColor,
            'onTap': () {
              Navigator.pop(context);
              context.go('/users');
            },
          },
          {
            'title': 'Operations',
            'icon': MdiIcons.shipWheel,
            'color': AppColors.primary,
            'onTap': () {
              Navigator.pop(context);
              context.go('/operations');
            },
          },
          {
            'title': 'Equipment',
            'icon': MdiIcons.crane,
            'color': AppColors.secondary,
            'onTap': () {
              Navigator.pop(context);
              context.go('/equipment');
            },
          },
          {
            'title': 'Equipment History',
            'icon': Icons.history,
            'color': AppColors.info,
            'onTap': () {
              Navigator.pop(context);
              context.go('/equipment/history');
            },
          },
          {
            'title': 'Financial',
            'icon': Icons.currency_rupee,
            'color': AppColors.success,
            'onTap': () {
              Navigator.pop(context);
              context.go('/financial');
            },
          },
          {
            'title': 'Reports',
            'icon': Icons.analytics,
            'color': AppColors.accent,
            'onTap': () {
              Navigator.pop(context);
              context.go('/reports');
            },
          },
        ];

      case 'manager':
        return [
          ...baseItems,
          {
            'title': 'Operations',
            'icon': MdiIcons.shipWheel,
            'color': AppColors.managerColor,
            'onTap': () {
              Navigator.pop(context);
              context.go('/operations');
            },
          },
          {
            'title': 'Equipment',
            'icon': MdiIcons.crane,
            'color': AppColors.secondary,
            'onTap': () {
              Navigator.pop(context);
              context.go('/equipment');
            },
          },
          {
            'title': 'Equipment History',
            'icon': Icons.history,
            'color': AppColors.info,
            'onTap': () {
              Navigator.pop(context);
              context.go('/equipment/history');
            },
          },
          {
            'title': 'Transport & Labour',
            'icon': Icons.local_shipping,
            'color': AppColors.warning,
            'onTap': () {
              Navigator.pop(context);
              context.go('/transport');
            },
          },
          {
            'title': 'Rate Master',
            'icon': Icons.monetization_on,
            'color': AppColors.accent,
            'onTap': () {
              Navigator.pop(context);
              context.go('/rates');
            },
          },
          {
            'title': 'Expense Approvals',
            'icon': Icons.approval,
            'color': AppColors.error,
            'badge': '0',
            'onTap': () {
              Navigator.pop(context);
              context.go('/expenses');
            },
          },
        ];

      case 'supervisor':
        return [
          ...baseItems,
          {
            'title': 'Equipment',
            'icon': MdiIcons.crane,
            'color': AppColors.supervisorColor,
            'onTap': () {
              Navigator.pop(context);
              context.go('/equipment');
            },
          },
          {
            'title': 'Equipment History',
            'icon': Icons.history,
            'color': AppColors.info,
            'onTap': () {
              Navigator.pop(context);
              context.go('/equipment/history');
            },
          },
          {
            'title': 'Wallet',
            'icon': Icons.account_balance_wallet,
            'color': AppColors.success,
            'onTap': () {
              Navigator.pop(context);
              context.go('/wallet');
            },
          },
          {
            'title': 'Port Expenses',
            'icon': Icons.receipt_long,
            'color': AppColors.warning,
            'onTap': () {
              Navigator.pop(context);
              context.go('/expenses');
            },
          },
          {
            'title': 'Digital Vouchers',
            'icon': Icons.camera_alt,
            'color': AppColors.secondary,
            'onTap': () {
              Navigator.pop(context);
              context.go('/vouchers');
            },
          },
        ];

      case 'accountant':
        return [
          ...baseItems,
          {
            'title': 'Expense Approvals',
            'icon': Icons.check_circle,
            'color': AppColors.accountantColor,
            'badge': '0',
            'onTap': () {
              Navigator.pop(context);
              context.go('/expenses');
            },
          },
          {
            'title': 'Voucher Approvals',
            'icon': Icons.description,
            'color': AppColors.warning,
            'badge': '0',
            'onTap': () {
              Navigator.pop(context);
              context.go('/vouchers');
            },
          },
          {
            'title': 'Wallet Management',
            'icon': Icons.add_card,
            'color': AppColors.primary,
            'onTap': () {
              Navigator.pop(context);
              context.go('/wallet');
            },
          },
          {
            'title': 'Revenue Streams',
            'icon': Icons.currency_rupee,
            'color': AppColors.success,
            'onTap': () {
              Navigator.pop(context);
              context.go('/revenue');
            },
          },
          {
            'title': 'Tally Integration',
            'icon': MdiIcons.fileDocumentOutline,
            'color': AppColors.accent,
            'onTap': () {
              Navigator.pop(context);
              context.go('/tally');
            },
          },
        ];

      default:
        return baseItems;
    }
  }

  Future<void> _showLogoutConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(authStateProvider.notifier).logout();
        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        // Handle any logout errors
        print('Logout error: $e');
      }
    }
  }
} 