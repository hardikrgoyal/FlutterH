import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/loading_widget.dart';

import '../../shared/models/user_model.dart';
import '../auth/auth_service.dart';
import 'wallet_provider.dart';
import 'wallet_service.dart';
import 'screens/create_expense_screen.dart';
import 'screens/create_voucher_screen.dart';
import 'screens/approvals_screen.dart';
import 'screens/wallet_history_screen.dart';
import 'screens/my_submissions_screen.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

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
        title: const Text('Wallet Management'),
        actions: [
          if (user.isAccountant || user.isAdmin) 
            IconButton(
              icon: const Icon(Icons.approval),
              onPressed: () => _showApprovalsDialog(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refreshWalletData(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: _buildFloatingActionButton(user),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: () async {
          if (user.hasWallet) {
            ref.refreshWalletData();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
        children: [
              if (user.hasWallet) ...[
          _buildWalletBalance(),
                _buildQuickActions(user),
                _buildTransactionsSection(),
              ],
              if (user.isAccountant) ...[
                _buildAccountantActions(),
                _buildAccountantTransactionsInfo(),
              ],
        ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(User user) {
    if (user.isAccountant || user.isAdmin) {
      return FloatingActionButton(
        onPressed: () => _showTopUpDialog(),
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  Widget _buildWalletBalance() {
    final balanceAsync = ref.watch(walletBalanceProvider);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: balanceAsync.when(
        data: (balance) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Balance',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.account_balance_wallet,
                  color: AppColors.white.withValues(alpha: 0.8),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
            Text(
              '₹${NumberFormat('#,##,###.##').format(balance.balance)}',
              style: const TextStyle(
              color: AppColors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
            Text(
              'Last updated: ${DateFormat('MMM dd, yyyy HH:mm').format(balance.lastUpdated)}',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(color: AppColors.white)),
        ),
        error: (error, stack) => SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'Error loading balance: $error',
              style: const TextStyle(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

    Widget _buildQuickActions(User user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (user.isSupervisor || user.isManager || user.isAdmin) ...[
            Expanded(
              child: _buildActionButton(
                'Port Expense',
                Icons.local_shipping,
                AppColors.info,
                () => _showCreateExpenseDialog(),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (user.hasWallet) ...[
            Expanded(
              child: _buildActionButton(
                'Digital Voucher',
                Icons.receipt_long,
                AppColors.success,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateVoucherScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (user.isSupervisor) ...[
            Expanded(
              child: _buildActionButton(
                'My Submissions',
                Icons.assignment,
                AppColors.warning,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MySubmissionsScreen()),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: _buildActionButton(
                'History',
                Icons.history,
                AppColors.warning,
                () => _scrollToTransactions(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountantTransactionsInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: AppColors.info),
              const SizedBox(width: 8),
              const Text(
                'Accountant Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'As an accountant, you can:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildInfoItem('• Top up wallets for users'),
          _buildInfoItem('• Approve port expenses and digital vouchers'),
          _buildInfoItem('• Download weekly Excel reports for Tally'),
          _buildInfoItem('• View and manage approval workflows'),
          const SizedBox(height: 12),
          const Text(
            'Note: Accountants do not have personal wallets. You manage wallets for other users.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildAccountantActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accountant Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
          Expanded(
            child: _buildActionButton(
                  'Approvals',
                  Icons.approval,
                  AppColors.primary,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ApprovalsScreen()),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
                  'Download Reports',
                  Icons.download,
                  AppColors.success,
                  () => _showDownloadDialog(),
            ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildFilterChips(),
            ],
          ),
          const SizedBox(height: 16),
          _buildTransactionsList(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filter = ref.watch(transactionFilterProvider);
    final filters = ['all', 'credit', 'debit'];
    
    return Row(
      children: filters.map((filterOption) {
        final isSelected = filter == filterOption;
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: FilterChip(
            label: Text(filterOption.toUpperCase()),
            selected: isSelected,
            onSelected: (selected) {
              ref.read(transactionFilterProvider.notifier).state = filterOption;
            },
          ),
          );
      }).toList(),
    );
  }

  Widget _buildTransactionsList() {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    
    return transactionsAsync.when(
      data: (transactions) {
    if (transactions.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
                    color: Colors.grey,
            ),
                  SizedBox(height: 16),
                  Text('No transactions found'),
          ],
              ),
        ),
      );
    }

    return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
      },
      loading: () => const LoadingWidget(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load transactions: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refreshWalletData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction transaction) {
    final isCredit = transaction.isCredit;
    final color = isCredit ? AppColors.success : AppColors.error;
    final icon = isCredit ? Icons.add : Icons.remove;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(transaction.description ?? 'Transaction'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM dd, yyyy HH:mm').format(transaction.date)),
            if (transaction.referenceId != null)
              Text(
                'Ref: ${transaction.referenceId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            if (transaction.approvedByName != null)
              Text(
                'Approved by: ${transaction.approvedByName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : '-'}₹${NumberFormat('#,##,###.##').format(transaction.amount)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '₹${NumberFormat('#,##,###.##').format(transaction.balanceAfter)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        isThreeLine: transaction.referenceId != null || transaction.approvedByName != null,
      ),
    );
  }

  void _scrollToTransactions() {
    // Scroll to transactions section
    Scrollable.ensureVisible(
      context,
      alignment: 0.0,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _showTopUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top Up Wallet'),
        content: const Text('Wallet top-up functionality coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCreateExpenseDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateExpenseScreen()),
    );
  }

  void _showApprovalsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approvals'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.approval),
              title: const Text('Pending Approvals'),
              subtitle: const Text('View and approve pending transactions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ApprovalsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Transaction History'),
              subtitle: const Text('View all past transactions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WalletHistoryScreen()),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Port Expenses'),
              subtitle: const Text('Weekly Excel report'),
              onTap: () {
                Navigator.pop(context);
                _downloadReport('port-expenses');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Digital Vouchers'),
              subtitle: const Text('Weekly Excel report'),
              onTap: () {
                Navigator.pop(context);
                _downloadReport('digital-vouchers');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _downloadReport(String reportType) async {
    try {
      final walletService = ref.read(walletServiceProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading report...'),
          backgroundColor: AppColors.info,
        ),
      );

      if (reportType == 'port-expenses') {
        await walletService.downloadPortExpensesExcel();
      } else {
        await walletService.downloadDigitalVouchersExcel();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report downloaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
} 