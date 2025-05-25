import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_drawer.dart';
import '../auth/auth_service.dart';

class FinancialScreen extends ConsumerStatefulWidget {
  const FinancialScreen({super.key});

  @override
  ConsumerState<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends ConsumerState<FinancialScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Overview', 'Expenses', 'Revenue', 'Vouchers'];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: _buildFloatingActionButton(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildExpensesTab(),
          _buildRevenueTab(),
          _buildVouchersTab(),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_selectedTabIndex) {
      case 1: // Expenses
        return FloatingActionButton(
          onPressed: () => context.go('/expenses/new'),
          child: const Icon(Icons.add),
        );
      case 3: // Vouchers
        return FloatingActionButton(
          onPressed: () => context.go('/vouchers/new'),
          child: const Icon(Icons.camera_alt),
        );
      default:
        return null;
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFinancialSummary(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Revenue',
                '₹12,45,000',
                AppColors.success,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Expenses',
                '₹8,75,000',
                AppColors.error,
                Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Net Profit',
                '₹3,70,000',
                AppColors.primary,
                Icons.account_balance,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Pending Approvals',
                '15',
                AppColors.warning,
                Icons.pending_actions,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildActionCard(
              'Add Expense',
              Icons.receipt_long,
              AppColors.error,
              () => context.go('/expenses/new'),
            ),
            _buildActionCard(
              'Add Voucher',
              Icons.camera_alt,
              AppColors.secondary,
              () => context.go('/vouchers/new'),
            ),
            _buildActionCard(
              'View Reports',
              Icons.analytics,
              AppColors.accent,
              () => context.go('/reports'),
            ),
            _buildActionCard(
              'Wallet Management',
              Icons.account_balance_wallet,
              AppColors.success,
              () => context.go('/wallet'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all transactions
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final transaction = _getDemoTransactions()[index];
            return _buildTransactionCard(transaction);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isExpense = transaction['type'] == 'expense';
    final color = isExpense ? AppColors.error : AppColors.success;
    final icon = isExpense ? Icons.remove : Icons.add;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(transaction['description'] as String),
        subtitle: Text(transaction['date'] as String),
        trailing: Text(
          '${isExpense ? '-' : '+'}₹${transaction['amount']}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _getDemoExpenses().length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final expense = _getDemoExpenses()[index];
        return _buildExpenseCard(expense);
      },
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final status = expense['status'] as String;
    final statusColor = _getStatusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    expense['description'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(expense['category'] as String),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(expense['date'] as String),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Requested by: ${expense['requestedBy']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '₹${expense['amount']}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _getDemoRevenue().length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final revenue = _getDemoRevenue()[index];
        return _buildRevenueCard(revenue);
      },
    );
  }

  Widget _buildRevenueCard(Map<String, dynamic> revenue) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              revenue['description'] as String,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.business, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(revenue['client'] as String),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(revenue['date'] as String),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Operation ID: ${revenue['operationId']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '₹${revenue['amount']}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVouchersTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _getDemoVouchers().length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final voucher = _getDemoVouchers()[index];
        return _buildVoucherCard(voucher);
      },
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final status = voucher['status'] as String;
    final statusColor = _getStatusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.textHint),
              ),
              child: const Icon(Icons.image, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voucher['description'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Amount: ₹${voucher['amount']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    voucher['date'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  List<Map<String, dynamic>> _getDemoTransactions() {
    return [
      {
        'description': 'Fuel for Crane Operations',
        'amount': '15,000',
        'date': 'Today',
        'type': 'expense',
      },
      {
        'description': 'Container Loading - MSC MONACO',
        'amount': '125,000',
        'date': 'Yesterday',
        'type': 'revenue',
      },
      {
        'description': 'Equipment Maintenance',
        'amount': '8,500',
        'date': '2 days ago',
        'type': 'expense',
      },
      {
        'description': 'Bulk Discharge - ATLANTIC STAR',
        'amount': '200,000',
        'date': '3 days ago',
        'type': 'revenue',
      },
      {
        'description': 'Labour Charges',
        'amount': '12,000',
        'date': '4 days ago',
        'type': 'expense',
      },
    ];
  }

  List<Map<String, dynamic>> _getDemoExpenses() {
    return [
      {
        'description': 'Fuel for Crane Operations',
        'amount': '15,000',
        'category': 'Fuel',
        'date': 'Today',
        'status': 'pending',
        'requestedBy': 'John Smith',
      },
      {
        'description': 'Equipment Maintenance',
        'amount': '8,500',
        'category': 'Maintenance',
        'date': '2 days ago',
        'status': 'approved',
        'requestedBy': 'Mike Johnson',
      },
      {
        'description': 'Labour Charges',
        'amount': '12,000',
        'category': 'Labour',
        'date': '4 days ago',
        'status': 'approved',
        'requestedBy': 'Sarah Davis',
      },
    ];
  }

  List<Map<String, dynamic>> _getDemoRevenue() {
    return [
      {
        'description': 'Container Loading - MSC MONACO',
        'amount': '125,000',
        'client': 'MSC Shipping',
        'date': 'Yesterday',
        'operationId': 'OP001',
      },
      {
        'description': 'Bulk Discharge - ATLANTIC STAR',
        'amount': '200,000',
        'client': 'Atlantic Shipping',
        'date': '3 days ago',
        'operationId': 'OP002',
      },
      {
        'description': 'Project Cargo - HEAVY LIFT',
        'amount': '350,000',
        'client': 'Heavy Lift Corp',
        'date': '1 week ago',
        'operationId': 'OP005',
      },
    ];
  }

  List<Map<String, dynamic>> _getDemoVouchers() {
    return [
      {
        'description': 'Fuel Receipt - Petrol Pump',
        'amount': '15,000',
        'date': 'Today',
        'status': 'pending',
      },
      {
        'description': 'Maintenance Bill - Workshop',
        'amount': '8,500',
        'date': '2 days ago',
        'status': 'approved',
      },
      {
        'description': 'Labour Payment Receipt',
        'amount': '12,000',
        'date': '4 days ago',
        'status': 'approved',
      },
    ];
  }
} 