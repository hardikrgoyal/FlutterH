import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../wallet_service.dart';

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
            _buildApprovalHistoryCard(),
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
            const SizedBox(height: 12),
            const Text(
              'Note: Detailed expense breakdown is calculated based on gate charges, vehicle type, and additional services.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
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
} 