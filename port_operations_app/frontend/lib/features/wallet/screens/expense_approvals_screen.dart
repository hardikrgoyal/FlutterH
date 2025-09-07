import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/auth_service.dart';
import '../wallet_provider.dart';
import '../wallet_service.dart';
import 'expense_detail_screen.dart';

class ExpenseApprovalsScreen extends ConsumerStatefulWidget {
  const ExpenseApprovalsScreen({super.key});

  @override
  ConsumerState<ExpenseApprovalsScreen> createState() => _ExpenseApprovalsScreenState();
}

class _ExpenseApprovalsScreenState extends ConsumerState<ExpenseApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Expense Approvals'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Icon(Icons.pending_actions),
              text: user.isAccountant ? 'Pending Finalization' : 'Pending Approval',
            ),
            const Tab(
              icon: Icon(Icons.check_circle),
              text: 'Approved',
            ),
            const Tab(
              icon: Icon(Icons.history),
              text: 'All Expenses',
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(user),
          _buildApprovedTab(user),
          _buildAllExpensesTab(user),
        ],
      ),
    );
  }

  Widget _buildPendingTab(User user) {
    final expensesAsync = ref.watch(allExpensesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(allExpensesProvider),
      child: expensesAsync.when(
        data: (expenses) {
          final filteredExpenses = expenses.where((expense) {
            if (user.isAccountant) {
              return expense.status == 'approved'; // Ready for finalization
            } else if (user.isManager || user.isAdmin) {
              return expense.status == 'submitted'; // Ready for approval
            }
            return false;
          }).toList();

          if (filteredExpenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    user.isAccountant ? Icons.task_alt : Icons.pending_actions,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.isAccountant 
                        ? 'No expenses pending finalization'
                        : 'No expenses pending approval',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.isAccountant
                        ? 'Approved expenses will appear here for finalization'
                        : 'Submitted expenses will appear here for approval',
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredExpenses.length,
            itemBuilder: (context, index) {
              final expense = filteredExpenses[index];
              return _buildExpenseCard(expense, user);
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

  Widget _buildApprovedTab(User user) {
    final expensesAsync = ref.watch(allExpensesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(allExpensesProvider),
      child: expensesAsync.when(
        data: (expenses) {
          final approvedExpenses = expenses.where((expense) {
            return expense.status == 'approved' || expense.status == 'finalized';
          }).toList();

          if (approvedExpenses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No approved expenses yet'),
                  SizedBox(height: 8),
                  Text(
                    'Approved expenses will appear here',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: approvedExpenses.length,
            itemBuilder: (context, index) {
              final expense = approvedExpenses[index];
              return _buildExpenseCard(expense, user, showActions: false);
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

  Widget _buildAllExpensesTab(User user) {
    final expensesAsync = ref.watch(allExpensesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(allExpensesProvider),
      child: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No expense history'),
                  SizedBox(height: 8),
                  Text(
                    'All expenses will appear here',
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
              return _buildExpenseCard(expense, user, showActions: false);
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

  Widget _buildExpenseCard(PortExpenseStatus expense, User user, {bool showActions = true}) {
    final statusColor = _getStatusColor(expense.status);
    final canApprove = _canApproveExpense(expense, user);
    final canFinalize = _canFinalizeExpense(expense, user);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewExpenseDetails(expense),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${expense.vehicle} ${expense.vehicleNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Gate: ${_getGateDisplayName(expense.gateNo)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: expense.inOut == 'In' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: expense.inOut == 'In' ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              expense.inOut,
                              style: TextStyle(
                                color: expense.inOut == 'In' ? Colors.green[700] : Colors.orange[700],
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.currency_rupee, size: 18, color: Colors.grey[600]),
                Text(
                  NumberFormat('#,##,###.##').format(expense.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(expense.dateTime),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            
            // Display description if available
            if (expense.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            expense.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (expense.reviewedByName != null || expense.approvedByName != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              _buildApprovalInfo(expense),
            ],
            if (showActions && (canApprove || canFinalize)) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildActionButtons(expense, user),
            ],
          ],
                 ), // closes Padding
       ), // closes InkWell
     ), // closes Card
     ); // closes method
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

  Widget _buildActionButtons(PortExpenseStatus expense, User user) {
    return Row(
      children: [
        if (_canApproveExpense(expense, user)) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showApprovalDialog(expense, 'approve'),
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showApprovalDialog(expense, 'reject'),
              icon: const Icon(Icons.cancel, size: 18),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
        if (_canFinalizeExpense(expense, user)) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showApprovalDialog(expense, 'finalize'),
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Finalize'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _canApproveExpense(PortExpenseStatus expense, User user) {
    return expense.status == 'submitted' && 
           (user.isManager || user.isAdmin);
  }

  bool _canFinalizeExpense(PortExpenseStatus expense, User user) {
    return expense.status == 'approved' && user.isAccountant;
  }

  void _showApprovalDialog(PortExpenseStatus expense, String action) {
    final TextEditingController commentsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getActionTitle(action)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${expense.vehicle} ${expense.vehicleNumber}'),
            Text('Gate: ${_getGateDisplayName(expense.gateNo)} (${expense.inOut})'),
            Text('Amount: ₹${NumberFormat('#,##,###.##').format(expense.totalAmount)}'),
            if (expense.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(expense.description),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expense Breakdown:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text('CISF: ₹${NumberFormat('#,##,###.##').format(expense.cisfAmount)}', style: const TextStyle(fontSize: 11)),
                  Text('KPT: ₹${NumberFormat('#,##,###.##').format(expense.kptAmount)}', style: const TextStyle(fontSize: 11)),
                  Text('Customs: ₹${NumberFormat('#,##,###.##').format(expense.customsAmount)}', style: const TextStyle(fontSize: 11)),
                  Text('Road Tax: ₹${NumberFormat('#,##,###.##').format(expense.roadTaxAmount)} (${expense.roadTaxDays} days)', style: const TextStyle(fontSize: 11)),
                  if (expense.otherCharges > 0)
                    Text('Other: ₹${NumberFormat('#,##,###.##').format(expense.otherCharges)}', style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: InputDecoration(
                labelText: action == 'reject' ? 'Rejection Reason *' : 'Comments (Optional)',
                border: const OutlineInputBorder(),
                hintText: _getCommentHint(action),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (action == 'reject' && commentsController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rejection reason is required'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              await _processApproval(expense, action, commentsController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getActionColor(action),
              foregroundColor: Colors.white,
            ),
            child: Text(_getActionTitle(action)),
          ),
        ],
      ),
    );
  }

  Future<void> _processApproval(PortExpenseStatus expense, String action, String comments) async {
    try {
      final walletService = ref.read(walletServiceProvider);
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Process the approval
      await walletService.approveExpense(expense.id, action, comments);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Refresh data
      ref.refresh(allExpensesProvider);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense ${action}d successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $action expense: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getActionTitle(String action) {
    switch (action) {
      case 'approve':
        return 'Approve Expense';
      case 'reject':
        return 'Reject Expense';
      case 'finalize':
        return 'Finalize Expense';
      default:
        return action;
    }
  }

  String _getCommentHint(String action) {
    switch (action) {
      case 'approve':
        return 'Add approval comments...';
      case 'reject':
        return 'Explain why this expense is being rejected...';
      case 'finalize':
        return 'Add finalization notes...';
      default:
        return 'Add comments...';
    }
  }

  void _viewExpenseDetails(PortExpenseStatus expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseDetailScreen(expense: expense),
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'approve':
      case 'finalize':
        return AppColors.success;
      case 'reject':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return AppColors.info;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'finalized':
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
} 