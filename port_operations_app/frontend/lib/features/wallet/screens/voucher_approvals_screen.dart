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
import 'voucher_detail_screen.dart';

class VoucherApprovalsScreen extends ConsumerStatefulWidget {
  const VoucherApprovalsScreen({super.key});

  @override
  ConsumerState<VoucherApprovalsScreen> createState() => _VoucherApprovalsScreenState();
}

class _VoucherApprovalsScreenState extends ConsumerState<VoucherApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text('Voucher Approvals'),
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
              text: user.isAccountant ? 'Pending Tally Log' : 'Pending Approval',
            ),
            const Tab(
              icon: Icon(Icons.check_circle),
              text: 'Approved',
            ),
            const Tab(
              icon: Icon(Icons.history),
              text: 'All Vouchers',
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
          _buildAllVouchersTab(user),
        ],
      ),
    );
  }

  Widget _buildPendingTab(User user) {
    final vouchersAsync = ref.watch(allVouchersProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(allVouchersProvider),
      child: vouchersAsync.when(
        data: (vouchers) {
          final filteredVouchers = vouchers.where((voucher) {
            if (user.isAccountant) {
              return voucher.status == 'approved'; // Ready for Tally logging
            } else if (user.isAdmin) {
              return voucher.status == 'submitted'; // Ready for approval
            }
            return false;
          }).toList();

          if (filteredVouchers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    user.isAccountant ? Icons.account_balance : Icons.pending_actions,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.isAccountant 
                        ? 'No vouchers pending Tally log'
                        : 'No vouchers pending approval',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.isAccountant
                        ? 'Approved vouchers will appear here for Tally logging'
                        : 'Submitted vouchers will appear here for approval',
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredVouchers.length,
            itemBuilder: (context, index) {
              final voucher = filteredVouchers[index];
              return _buildVoucherCard(voucher, user);
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

  Widget _buildApprovedTab(User user) {
    final vouchersAsync = ref.watch(allVouchersProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(allVouchersProvider),
      child: vouchersAsync.when(
        data: (vouchers) {
          final approvedVouchers = vouchers.where((voucher) {
            return voucher.status == 'approved' || voucher.status == 'logged';
          }).toList();

          if (approvedVouchers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No approved vouchers yet'),
                  SizedBox(height: 8),
                  Text(
                    'Approved vouchers will appear here',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: approvedVouchers.length,
            itemBuilder: (context, index) {
              final voucher = approvedVouchers[index];
              return _buildVoucherCard(voucher, user, showActions: false);
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

  Widget _buildAllVouchersTab(User user) {
    final vouchersAsync = ref.watch(allVouchersProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(allVouchersProvider),
      child: vouchersAsync.when(
        data: (vouchers) {
          if (vouchers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No voucher history'),
                  SizedBox(height: 8),
                  Text(
                    'All vouchers will appear here',
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
              return _buildVoucherCard(voucher, user, showActions: false);
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

  Widget _buildVoucherCard(VoucherStatus voucher, User user, {bool showActions = true}) {
    final statusColor = _getStatusColor(voucher.status);
    final canApprove = _canApproveVoucher(voucher, user);
    final canLog = _canLogVoucher(voucher, user);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewVoucherDetails(voucher),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_getCategoryIcon(voucher.expenseCategory), 
                                 size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getCategoryDisplayName(voucher.expenseCategory),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(voucher.dateTime),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
              
              const SizedBox(height: 12),
              
              // Amount and submitter info
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.currency_rupee, size: 18, color: Colors.grey[600]),
                        Text(
                          NumberFormat('#,##,###.##').format(voucher.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          voucher.userName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Key information preview
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (voucher.remarks != null && voucher.remarks!.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(Icons.note, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    voucher.remarks!.length > 50 
                                        ? '${voucher.remarks!.substring(0, 50)}...'
                                        : voucher.remarks!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (voucher.billPhotoUrl != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.photo, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Bill photo attached',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
              
              // Approval information
              if (voucher.approvedByName != null || voucher.loggedByName != null || voucher.tallyReference != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                _buildApprovalInfo(voucher),
              ],
              
              // Action buttons
              if (showActions && (canApprove || canLog)) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewVoucherDetails(voucher),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionButton(voucher, user),
                    ),
                  ],
                ),
              ] else if (showActions) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _viewVoucherDetails(voucher),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalInfo(VoucherStatus voucher) {
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

  Widget _buildActionButtons(VoucherStatus voucher, User user) {
    return Row(
      children: [
        if (_canApproveVoucher(voucher, user)) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showApprovalDialog(voucher, 'approve'),
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
              onPressed: () => _showApprovalDialog(voucher, 'decline'),
              icon: const Icon(Icons.cancel, size: 18),
              label: const Text('Decline'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
        if (_canLogVoucher(voucher, user)) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showTallyLogDialog(voucher),
              icon: const Icon(Icons.account_balance, size: 18),
              label: const Text('Log to Tally'),
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

  bool _canApproveVoucher(VoucherStatus voucher, User user) {
    return voucher.status == 'submitted' && user.isAdmin;
  }

  bool _canLogVoucher(VoucherStatus voucher, User user) {
    return voucher.status == 'approved' && user.isAccountant;
  }

  void _showApprovalDialog(VoucherStatus voucher, String action) {
    final TextEditingController commentsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getActionTitle(action)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getCategoryDisplayName(voucher.expenseCategory)),
            Text('Amount: ₹${NumberFormat('#,##,###.##').format(voucher.amount)}'),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: InputDecoration(
                labelText: action == 'decline' ? 'Decline Reason *' : 'Comments (Optional)',
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
              if (action == 'decline' && commentsController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Decline reason is required'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              await _processApproval(voucher, action, commentsController.text.trim());
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

  void _showTallyLogDialog(VoucherStatus voucher) {
    final TextEditingController commentsController = TextEditingController();
    final TextEditingController tallyRefController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log to Tally'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getCategoryDisplayName(voucher.expenseCategory)),
            Text('Amount: ₹${NumberFormat('#,##,###.##').format(voucher.amount)}'),
            const SizedBox(height: 16),
            TextField(
              controller: tallyRefController,
              decoration: const InputDecoration(
                labelText: 'Tally Reference *',
                border: OutlineInputBorder(),
                hintText: 'Enter Tally voucher reference...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Comments (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Add logging comments...',
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
              if (tallyRefController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tally reference is required'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              await _processTallyLog(voucher, commentsController.text.trim(), tallyRefController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log to Tally'),
          ),
        ],
      ),
    );
  }

  Future<void> _processApproval(VoucherStatus voucher, String action, String comments) async {
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
      await walletService.approveVoucher(voucher.id, action, comments);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Refresh data
      ref.refresh(allVouchersProvider);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voucher ${action}d successfully'),
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
            content: Text('Failed to $action voucher: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _processTallyLog(VoucherStatus voucher, String comments, String tallyReference) async {
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
      
      // Process the Tally logging
      await walletService.approveVoucher(voucher.id, 'log', comments, tallyReference: tallyReference);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Refresh data
      ref.refresh(allVouchersProvider);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voucher logged to Tally successfully'),
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
            content: Text('Failed to log voucher to Tally: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getActionTitle(String action) {
    switch (action) {
      case 'approve':
        return 'Approve Voucher';
      case 'decline':
        return 'Decline Voucher';
      case 'log':
        return 'Log to Tally';
      default:
        return action;
    }
  }

  String _getCommentHint(String action) {
    switch (action) {
      case 'approve':
        return 'Add approval comments...';
      case 'decline':
        return 'Explain why this voucher is being declined...';
      case 'log':
        return 'Add Tally logging notes...';
      default:
        return 'Add comments...';
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'approve':
      case 'log':
        return AppColors.success;
      case 'decline':
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
      case 'declined':
        return AppColors.error;
      case 'logged':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'fuel':
        return Icons.local_gas_station;
      case 'maintenance':
        return Icons.build;
      case 'office_supplies':
        return Icons.inventory;
      case 'equipment':
        return Icons.construction;
      case 'travel':
        return Icons.flight;
      case 'food':
        return Icons.restaurant;
      case 'accommodation':
        return Icons.hotel;
      case 'transport':
        return Icons.directions_car;
      case 'communication':
        return Icons.phone;
      case 'utilities':
        return Icons.electrical_services;
      case 'professional_services':
        return Icons.business;
      case 'others':
        return Icons.category;
      default:
        return Icons.receipt;
    }
  }

  void _viewVoucherDetails(VoucherStatus voucher) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoucherDetailScreen(voucher: voucher),
      ),
    );
  }

  Widget _buildQuickActionButton(VoucherStatus voucher, User user) {
    final canApprove = _canApproveVoucher(voucher, user);
    final canLog = _canLogVoucher(voucher, user);

    if (canApprove) {
      return ElevatedButton.icon(
        onPressed: () => _showApprovalDialog(voucher, 'approve'),
        icon: const Icon(Icons.check, size: 18),
        label: const Text('Approve'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      );
    } else if (canLog) {
      return ElevatedButton.icon(
        onPressed: () => _showApprovalDialog(voucher, 'log'),
        icon: const Icon(Icons.account_balance, size: 18),
        label: const Text('Log to Tally'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.info, size: 18),
        label: const Text('No Action'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      );
    }
  }
} 