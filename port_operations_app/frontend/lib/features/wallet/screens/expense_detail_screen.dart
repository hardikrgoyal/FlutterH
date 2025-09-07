import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../wallet_service.dart';
import '../wallet_provider.dart';
import '../../auth/auth_service.dart';
import '../../../shared/models/user_model.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final PortExpenseStatus expense;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
  });

  @override
  ConsumerState<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final showApprovalActions = user != null && _canShowApprovalActions(user);

    return Scaffold(
      appBar: AppBar(
        title: Text('Expense #${widget.expense.id}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareExpense,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildBasicInfoCard(),
            const SizedBox(height: 16),
            _buildVehicleInfoCard(),
            const SizedBox(height: 16),
            _buildExpenseBreakdownCard(),
            const SizedBox(height: 16),
            if (widget.expense.photo != null) ...[
              _buildPhotoCard(),
              const SizedBox(height: 16),
            ],
            _buildApprovalHistoryCard(),
            if (showApprovalActions) ...[
              const SizedBox(height: 16),
              _buildApprovalActionsCard(user!),
            ],
            const SizedBox(height: 80), // Extra space for content
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(widget.expense.status);
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              statusColor.withValues(alpha: 0.1),
              statusColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getStatusIcon(widget.expense.status),
              size: 48,
              color: statusColor,
            ),
            const SizedBox(height: 12),
            Text(
              widget.expense.status.toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Amount: ₹${NumberFormat('#,##,###.##').format(widget.expense.totalAmount)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Expense Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Expense ID', '#${widget.expense.id}'),
            const SizedBox(height: 12),
            _buildInfoRow('Date & Time', DateFormat('dd MMM yyyy, hh:mm a').format(widget.expense.dateTime)),
            const SizedBox(height: 12),
            _buildInfoRow('Gate', _getGateDisplayName(widget.expense.gateNo)),
            const SizedBox(height: 12),
            _buildInfoRow('Submitted On', DateFormat('dd MMM yyyy, hh:mm a').format(widget.expense.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Vehicle Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Vehicle Type', widget.expense.vehicle),
            const SizedBox(height: 12),
            _buildInfoRow('Vehicle Number', widget.expense.vehicleNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseBreakdownCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Expense Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Individual expense items
            _buildExpenseItem('CISF Charges', widget.expense.cisfAmount),
            _buildExpenseItem('KPT Charges', widget.expense.kptAmount),
            _buildExpenseItem('Customs Charges', widget.expense.customsAmount),
            _buildExpenseItem(
              'Road Tax (${widget.expense.roadTaxDays} ${widget.expense.roadTaxDays == 1 ? 'day' : 'days'})', 
              widget.expense.roadTaxAmount
            ),
            if (widget.expense.otherCharges > 0)
              _buildExpenseItem('Other Charges', widget.expense.otherCharges),
            
            const SizedBox(height: 12),
            const Divider(thickness: 1),
            const SizedBox(height: 8),
            
            // Total amount
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${NumberFormat('#,##,###.##').format(widget.expense.totalAmount)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            '₹${NumberFormat('#,##,###.##').format(amount)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Document Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.expense.photo!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey.shade100,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Road tax receipt or official document',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalHistoryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Approval History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              icon: Icons.upload_file,
              title: 'Expense Submitted',
              subtitle: 'Expense submitted for approval',
              timestamp: widget.expense.createdAt,
              isCompleted: true,
            ),
            if (widget.expense.reviewedByName != null)
              _buildTimelineItem(
                icon: Icons.rate_review,
                title: 'Reviewed by Manager',
                subtitle: 'By ${widget.expense.reviewedByName}',
                timestamp: widget.expense.createdAt, // Add reviewed_at field to backend if needed
                isCompleted: true,
              ),
            if (widget.expense.approvedByName != null)
              _buildTimelineItem(
                icon: Icons.check_circle,
                title: 'Approved by Admin',
                subtitle: 'By ${widget.expense.approvedByName}',
                timestamp: widget.expense.createdAt, // Add approved_at field to backend if needed
                isCompleted: true,
              ),
            if (widget.expense.status == 'submitted')
              _buildTimelineItem(
                icon: Icons.pending,
                title: 'Awaiting Approval',
                subtitle: 'Pending manager/admin approval',
                timestamp: null,
                isCompleted: false,
              ),
            if (widget.expense.reviewComments != null && widget.expense.reviewComments!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.comment, color: AppColors.info, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Comments',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.expense.reviewComments!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required DateTime? timestamp,
    required bool isCompleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success : AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (timestamp != null)
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
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
        return AppColors.error;
      case 'finalized':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Icons.upload_file;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'finalized':
        return Icons.verified;
      default:
        return Icons.help_outline;
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

  void _shareExpense() {
    // Implement share functionality if needed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
      ),
    );
  }

  bool _canShowApprovalActions(User user) {
    // Show approval actions if user can approve and expense is in pending status
    return (user.isAdmin || user.isManager || user.isAccountant) && 
           (widget.expense.status == 'submitted' || widget.expense.status == 'approved');
  }

  Widget _buildApprovalActionsCard(User user) {
    final canApprove = widget.expense.status == 'submitted' && (user.isAdmin || user.isManager);
    final canFinalize = widget.expense.status == 'approved' && user.isAccountant;

    if (!canApprove && !canFinalize) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Approval Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (canApprove) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showApprovalDialog('approve'),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showApprovalDialog('reject'),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (canFinalize) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showApprovalDialog('finalize'),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Finalize Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showApprovalDialog(String action) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getActionTitle(action)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: _getCommentHint(action),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processApproval(action, controller.text);
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

  Future<void> _processApproval(String action, String comments) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final walletService = ref.read(walletServiceProvider);
      await walletService.approveExpense(widget.expense.id, action, comments);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Refresh data
      ref.refresh(allExpensesProvider);
      
      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense ${action}d successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
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

  Color _getActionColor(String action) {
    switch (action) {
      case 'approve':
        return AppColors.success;
      case 'reject':
        return AppColors.error;
      case 'finalize':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }
} 