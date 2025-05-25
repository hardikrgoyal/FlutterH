import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_drawer.dart';
import '../auth/auth_service.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'credit', 'debit'];

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
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show transaction history
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: user.isAccountant || user.isAdmin
          ? FloatingActionButton(
              onPressed: () => _showAddFundsDialog(),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          _buildWalletBalance(),
          _buildQuickActions(),
          _buildFilterChips(),
          Expanded(
            child: _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletBalance() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
                color: AppColors.white.withOpacity(0.8),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '₹2,45,750',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppColors.white.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '+₹15,000 this month',
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Add Funds',
              Icons.add_circle,
              AppColors.success,
              () => _showAddFundsDialog(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'Transfer',
              Icons.swap_horiz,
              AppColors.info,
              () => _showTransferDialog(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'Withdraw',
              Icons.remove_circle,
              AppColors.warning,
              () => _showWithdrawDialog(),
            ),
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

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return FilterChip(
            label: Text(filter.toUpperCase()),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = filter;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionsList() {
    final transactions = _getFilteredTransactions();
    
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isCredit = transaction['type'] == 'credit';
    final color = isCredit ? AppColors.success : AppColors.error;
    final icon = isCredit ? Icons.add : Icons.remove;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(transaction['description'] as String),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction['date'] as String),
            if (transaction['reference'] != null)
              Text(
                'Ref: ${transaction['reference']}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : '-'}₹${transaction['amount']}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '₹${transaction['balance']}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        isThreeLine: transaction['reference'] != null,
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    final allTransactions = _getDemoTransactions();
    
    if (_selectedFilter == 'all') {
      return allTransactions;
    }
    
    return allTransactions.where((tx) => tx['type'] == _selectedFilter).toList();
  }

  List<Map<String, dynamic>> _getDemoTransactions() {
    return [
      {
        'description': 'Funds Added - Bank Transfer',
        'amount': '50,000',
        'type': 'credit',
        'date': 'Today, 2:30 PM',
        'reference': 'TXN123456789',
        'balance': '2,45,750',
      },
      {
        'description': 'Equipment Fuel Payment',
        'amount': '15,000',
        'type': 'debit',
        'date': 'Today, 10:15 AM',
        'reference': 'EXP001',
        'balance': '1,95,750',
      },
      {
        'description': 'Revenue from MSC MONACO',
        'amount': '125,000',
        'type': 'credit',
        'date': 'Yesterday, 4:45 PM',
        'reference': 'OP001',
        'balance': '2,10,750',
      },
      {
        'description': 'Labour Payment',
        'amount': '12,000',
        'type': 'debit',
        'date': 'Yesterday, 11:20 AM',
        'reference': 'LAB001',
        'balance': '85,750',
      },
      {
        'description': 'Equipment Maintenance',
        'amount': '8,500',
        'type': 'debit',
        'date': '2 days ago',
        'reference': 'MAINT001',
        'balance': '97,750',
      },
      {
        'description': 'Revenue from ATLANTIC STAR',
        'amount': '200,000',
        'type': 'credit',
        'date': '3 days ago',
        'reference': 'OP002',
        'balance': '1,06,250',
      },
    ];
  }

  void _showAddFundsDialog() {
    final amountController = TextEditingController();
    final referenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funds added successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Add Funds'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog() {
    final amountController = TextEditingController();
    final toController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: toController,
              decoration: const InputDecoration(
                labelText: 'Transfer To',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transfer initiated successfully!'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Available Balance: ₹2,45,750',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Withdrawal request submitted!'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
} 