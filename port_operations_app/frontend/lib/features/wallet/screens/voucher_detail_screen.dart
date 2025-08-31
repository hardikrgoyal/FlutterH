import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/auth_service.dart';
import '../wallet_service.dart';
import '../wallet_provider.dart';

class VoucherDetailScreen extends ConsumerStatefulWidget {
  final VoucherStatus voucher;

  const VoucherDetailScreen({
    super.key,
    required this.voucher,
  });

  @override
  ConsumerState<VoucherDetailScreen> createState() => _VoucherDetailScreenState();
}

class _VoucherDetailScreenState extends ConsumerState<VoucherDetailScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voucher #${widget.voucher.id}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareVoucher,
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
            _buildSubmitterInfoCard(),
            const SizedBox(height: 16),
            if (widget.voucher.billPhotoUrl != null) ...[
              _buildBillPhotoCard(),
              const SizedBox(height: 16),
            ],
            if (widget.voucher.remarks != null && widget.voucher.remarks!.isNotEmpty) ...[
              _buildRemarksCard(),
              const SizedBox(height: 16),
            ],
            _buildApprovalHistoryCard(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 80), // Extra space for FAB
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(widget.voucher.status);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStatusIcon(widget.voucher.status),
                color: statusColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.voucher.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted ${_getTimeAgo(widget.voucher.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${NumberFormat('#,##,###.##').format(widget.voucher.amount)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  _getCategoryDisplayName(widget.voucher.expenseCategory),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
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
                  'Voucher Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Voucher ID', '#${widget.voucher.id}'),
            const SizedBox(height: 12),
            _buildInfoRow('Category', _getCategoryDisplayName(widget.voucher.expenseCategory)),
            const SizedBox(height: 12),
            _buildInfoRow('Amount', '₹${NumberFormat('#,##,###.##').format(widget.voucher.amount)}'),
            const SizedBox(height: 12),
            _buildInfoRow('Date & Time', DateFormat('dd MMM yyyy, hh:mm a').format(widget.voucher.dateTime)),
            const SizedBox(height: 12),
            _buildInfoRow('Submitted On', DateFormat('dd MMM yyyy, hh:mm a').format(widget.voucher.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitterInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Submitted By',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    widget.voucher.userName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.voucher.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'User',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _contactSubmitter,
                  icon: const Icon(Icons.message),
                  tooltip: 'Contact Submitter',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillPhotoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Bill Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _viewFullScreenImage(widget.voucher.billPhotoUrl!),
                  icon: const Icon(Icons.fullscreen),
                  label: const Text('View Full'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.voucher.billPhotoUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[100],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Remarks',
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                widget.voucher.remarks!,
                style: const TextStyle(fontSize: 16),
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
              title: 'Voucher Submitted',
              subtitle: 'By ${widget.voucher.userName}',
              timestamp: widget.voucher.createdAt,
              isCompleted: true,
            ),
            if (widget.voucher.approvedByName != null)
              _buildTimelineItem(
                icon: Icons.check_circle,
                title: 'Approved by Admin',
                subtitle: 'By ${widget.voucher.approvedByName}',
                timestamp: widget.voucher.createdAt, // You might want to add approved_at field
                isCompleted: true,
              ),
            if (widget.voucher.loggedByName != null)
              _buildTimelineItem(
                icon: Icons.account_balance,
                title: 'Logged to Tally',
                subtitle: 'By ${widget.voucher.loggedByName}',
                timestamp: widget.voucher.createdAt, // You might want to add logged_at field
                isCompleted: true,
              ),
            if (widget.voucher.status == 'submitted')
              _buildTimelineItem(
                icon: Icons.pending,
                title: 'Pending Admin Approval',
                subtitle: 'Waiting for admin review',
                timestamp: null,
                isCompleted: false,
              ),
            if (widget.voucher.status == 'approved')
              _buildTimelineItem(
                icon: Icons.pending,
                title: 'Pending Tally Logging',
                subtitle: 'Waiting for accountant',
                timestamp: null,
                isCompleted: false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    DateTime? timestamp,
    required bool isCompleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isCompleted ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.black : Colors.grey[600],
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

  Widget _buildActionButtons() {
    final user = ref.watch(authStateProvider).user;
    if (user == null) return const SizedBox.shrink();

    final canApprove = _canApproveVoucher(widget.voucher, user);
    final canLog = _canLogVoucher(widget.voucher, user);

    if (!canApprove && !canLog) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (canApprove) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _approveVoucher('approve'),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : () => _approveVoucher('decline'),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (canLog) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _approveVoucher('log'),
                  icon: const Icon(Icons.account_balance),
                  label: const Text('Log to Tally'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back),
      label: const Text('Back'),
      backgroundColor: AppColors.primary,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
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

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'logged':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle_outline;
      case 'logged':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      default:
        return Icons.help_outline;
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
      case 'equipment':
        return 'Equipment';
      case 'travel':
        return 'Travel';
      case 'others':
        return 'Others';
      default:
        return category.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  bool _canApproveVoucher(VoucherStatus voucher, User user) {
    return user.isAdmin && voucher.status == 'submitted';
  }

  bool _canLogVoucher(VoucherStatus voucher, User user) {
    return user.isAccountant && voucher.status == 'approved';
  }

  // Action methods
  void _shareVoucher() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _contactSubmitter() {
    // TODO: Implement contact functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact functionality coming soon')),
    );
  }

  void _viewFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 64, color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveVoucher(String action) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      String? comments;
      String? tallyReference;

      if (action == 'log') {
        // Show Tally reference dialog
        final result = await _showTallyDialog();
        if (result == null) {
          setState(() {
            _isProcessing = false;
          });
          return;
        }
        tallyReference = result['tallyReference'];
        comments = result['comments'];
      } else {
        // Show comments dialog
        comments = await _showCommentsDialog(action);
        if (comments == null) {
          setState(() {
            _isProcessing = false;
          });
          return;
        }
      }

      final walletService = ref.read(walletServiceProvider);
      await walletService.approveVoucher(
        widget.voucher.id,
        action,
        comments ?? '',
        tallyReference: tallyReference,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voucher ${action}d successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh data and navigate back
        ref.refresh(allVouchersProvider);
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $action voucher: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<String?> _showCommentsDialog(String action) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.capitalize()} Voucher'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Comments (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(action.capitalize()),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>?> _showTallyDialog() async {
    final tallyController = TextEditingController();
    final commentsController = TextEditingController();
    
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log to Tally'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tallyController,
              decoration: const InputDecoration(
                labelText: 'Tally Reference *',
                hintText: 'Enter Tally voucher number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Comments (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
              if (tallyController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tally reference is required')),
                );
                return;
              }
              Navigator.pop(context, {
                'tallyReference': tallyController.text,
                'comments': commentsController.text,
              });
            },
            child: const Text('Log to Tally'),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 