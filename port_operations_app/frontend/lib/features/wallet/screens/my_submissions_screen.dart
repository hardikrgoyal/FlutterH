import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../wallet_provider.dart';
import '../wallet_service.dart';

class MySubmissionsScreen extends ConsumerStatefulWidget {
  const MySubmissionsScreen({super.key});

  @override
  ConsumerState<MySubmissionsScreen> createState() => _MySubmissionsScreenState();
}

class _MySubmissionsScreenState extends ConsumerState<MySubmissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Submissions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.local_shipping),
              text: 'Port Expenses',
            ),
            Tab(
              icon: Icon(Icons.receipt_long),
              text: 'Digital Vouchers',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpensesTab(),
          _buildVouchersTab(),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    final expensesAsync = ref.watch(myExpensesProvider);
    
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(myExpensesProvider),
      child: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No port expenses submitted yet'),
                  SizedBox(height: 8),
                  Text(
                    'Your submitted expenses will appear here',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return _buildExpenseCard(expense);
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
              Text('Failed to load expenses: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(myExpensesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVouchersTab() {
    final vouchersAsync = ref.watch(myVouchersProvider);
    
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(myVouchersProvider),
      child: vouchersAsync.when(
        data: (vouchers) {
          if (vouchers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No digital vouchers submitted yet'),
                  SizedBox(height: 8),
                  Text(
                    'Your submitted vouchers will appear here',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              final voucher = vouchers[index];
              return _buildVoucherCard(voucher);
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
              Text('Failed to load vouchers: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(myVouchersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseCard(PortExpenseStatus expense) {
    final statusColor = _getStatusColor(expense.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    '${expense.vehicle} ${expense.vehicleNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    expense.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Gate: ${_getGateDisplayName(expense.gateNo)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(Icons.currency_rupee, size: 16, color: Colors.grey[600]),
                Text(
                  NumberFormat('#,##,###.##').format(expense.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(expense.dateTime),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (expense.reviewedByName != null || expense.approvedByName != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              _buildApprovalInfo(expense),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherCard(VoucherStatus voucher) {
    final statusColor = _getStatusColor(voucher.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    _getCategoryDisplayName(voucher.expenseCategory),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    voucher.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.currency_rupee, size: 16, color: Colors.grey[600]),
                Text(
                  NumberFormat('#,##,###.##').format(voucher.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(voucher.dateTime),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (voucher.approvedByName != null || voucher.loggedByName != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              _buildVoucherApprovalInfo(voucher),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalInfo(PortExpenseStatus expense) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Approval Status:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        if (expense.reviewedByName != null)
          Text(
            'Reviewed by: ${expense.reviewedByName}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        if (expense.approvedByName != null)
          Text(
            'Approved by: ${expense.approvedByName}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        if (expense.reviewComments != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Comments: ${expense.reviewComments}',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVoucherApprovalInfo(VoucherStatus voucher) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Approval Status:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        if (voucher.approvedByName != null)
          Text(
            'Approved by: ${voucher.approvedByName}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        if (voucher.loggedByName != null)
          Text(
            'Logged by: ${voucher.loggedByName}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        if (voucher.tallyReference != null)
          Text(
            'Tally Reference: ${voucher.tallyReference}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        if (voucher.approvalComments != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Comments: ${voucher.approvalComments}',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return AppColors.info;
      case 'approved':
        return AppColors.success;
      case 'rejected':
      case 'declined':
        return AppColors.error;
      case 'finalized':
      case 'logged':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getGateDisplayName(String gateNo) {
    switch (gateNo) {
      case 'gate_1':
        return 'Gate 1';
      case 'gate_2':
        return 'Gate 2';
      case 'gate_3':
        return 'Gate 3';
      case 'main_gate':
        return 'Main Gate';
      default:
        return gateNo;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'fuel':
        return 'Fuel';
      case 'maintenance':
        return 'Maintenance';
      case 'office_supplies':
        return 'Office Supplies';
      case 'travel':
        return 'Travel';
      case 'meals':
        return 'Meals';
      case 'communication':
        return 'Communication';
      case 'utilities':
        return 'Utilities';
      case 'professional_services':
        return 'Professional Services';
      case 'others':
        return 'Others';
      default:
        return category;
    }
  }
} 