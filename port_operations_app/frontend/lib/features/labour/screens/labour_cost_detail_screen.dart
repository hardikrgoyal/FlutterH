import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/models/labour_cost_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../labour_service.dart';
import '../../auth/auth_service.dart';

class LabourCostDetailScreen extends ConsumerStatefulWidget {
  final int labourCostId;

  const LabourCostDetailScreen({
    super.key,
    required this.labourCostId,
  });

  @override
  ConsumerState<LabourCostDetailScreen> createState() => _LabourCostDetailScreenState();
}

class _LabourCostDetailScreenState extends ConsumerState<LabourCostDetailScreen> {
  LabourCost? _labourCost;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLabourCost();
  }

  Future<void> _loadLabourCost() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final labourService = ref.read(labourServiceProvider);
      _labourCost = await labourService.getLabourCost(widget.labourCostId);
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Labour Cost Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_labourCost != null && user.canEditLabourCosts)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    context.push('/labour/${widget.labourCostId}/edit');
                    break;
                  case 'delete':
                    _showDeleteDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading labour cost details...');
    }

    if (_error != null) {
      return AppErrorWidget(
        message: _error!,
        onRetry: _loadLabourCost,
      );
    }

    if (_labourCost == null) {
      return const AppErrorWidget(
        message: 'Labour cost not found',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLabourCost,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            const SizedBox(height: 16),
            _buildCostBreakdownCard(),
            if (_labourCost!.remarks?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _buildRemarksCard(),
            ],
            const SizedBox(height: 16),
            _buildMetadataCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _getLabourTypeGradient(_labourCost!.labourType),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.accountGroup,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labourCost!.contractorName ?? 'Unknown Contractor',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_labourCost!.labourTypeDisplay} • ${_labourCost!.workTypeDisplay}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      '₹${NumberFormat('#,##0.00').format(_labourCost!.amount ?? _labourCost!.calculatedAmount)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Date',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(_labourCost!.date),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Labour Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Operation',
              _labourCost!.operationName ?? 'N/A',
              Icons.business,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Contractor',
              _labourCost!.contractorName ?? 'Unknown Contractor',
              Icons.person,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Labour Type',
              _labourCost!.labourTypeDisplay,
              Icons.group,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Work Type',
              _labourCost!.workTypeDisplay,
              Icons.work,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBreakdownCard() {
    final user = ref.read(authStateProvider).user!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cost Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Labour Count/Tonnage:',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '${_labourCost!.labourCountTonnage}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (user.canAccessCostDetails) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rate per unit:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          '₹${NumberFormat('#,##0.00').format(_labourCost!.rate ?? 0)}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${NumberFormat('#,##0.00').format(_labourCost!.amount ?? _labourCost!.calculatedAmount)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remarks',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _labourCost!.remarks!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_labourCost!.createdByName != null)
              _buildDetailRow(
                'Created By',
                _labourCost!.createdByName!,
                Icons.person_outline,
              ),
            if (_labourCost!.createdAt != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
                'Created At',
                DateFormat('MMM dd, yyyy • hh:mm a').format(_labourCost!.createdAt!),
                Icons.access_time,
              ),
            ],
            if (_labourCost!.updatedAt != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
                'Last Updated',
                DateFormat('MMM dd, yyyy • hh:mm a').format(_labourCost!.updatedAt!),
                Icons.update,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textHint,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  LinearGradient _getLabourTypeGradient(String labourType) {
    switch (labourType) {
      case 'casual':
        return LinearGradient(
          colors: [AppColors.info, AppColors.info.withOpacity(0.8)],
        );
      case 'skilled':
        return LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        );
      case 'operator':
        return LinearGradient(
          colors: [AppColors.warning, AppColors.warning.withOpacity(0.8)],
        );
      case 'supervisor':
        return LinearGradient(
          colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
        );
      case 'others':
        return LinearGradient(
          colors: [AppColors.accent, AppColors.accent.withOpacity(0.8)],
        );
      default:
        return LinearGradient(
          colors: [AppColors.grey400, AppColors.grey400.withOpacity(0.8)],
        );
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Labour Cost'),
        content: Text(
          'Are you sure you want to delete the labour cost for ${_labourCost!.contractorName ?? 'Unknown Contractor'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteLabourCost();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLabourCost() async {
    try {
      await ref.read(labourCostProvider.notifier).deleteLabourCost(_labourCost!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Labour cost deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete labour cost: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
} 