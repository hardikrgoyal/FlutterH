import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/models/miscellaneous_cost_model.dart';
import '../services/miscellaneous_service.dart';
import '../../auth/auth_service.dart';

class MiscellaneousDetailScreen extends ConsumerStatefulWidget {
  final int costId;

  const MiscellaneousDetailScreen({
    super.key,
    required this.costId,
  });

  @override
  ConsumerState<MiscellaneousDetailScreen> createState() => _MiscellaneousDetailScreenState();
}

class _MiscellaneousDetailScreenState extends ConsumerState<MiscellaneousDetailScreen> {
  MiscellaneousCost? _miscCost;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final cost = await ref.read(miscellaneousCostProvider.notifier).getMiscellaneousCost(widget.costId);
      
      if (mounted) {
        setState(() {
          _miscCost = cost;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Miscellaneous Cost'),
        content: const Text('Are you sure you want to delete this miscellaneous cost? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await ref.read(miscellaneousCostProvider.notifier).deleteMiscellaneousCost(widget.costId);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Miscellaneous cost deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete miscellaneous cost'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final canEdit = user?.role == 'manager' || user?.role == 'admin';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Miscellaneous Cost Detail'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Miscellaneous Cost Detail'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error Loading Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_miscCost == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Miscellaneous Cost Detail'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Miscellaneous cost not found'),
        ),
      );
    }

    final costTypeColor = Color(int.parse(_miscCost!.costTypeColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Miscellaneous Cost Detail'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (canEdit) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/miscellaneous/${widget.costId}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCost,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [costTypeColor.withValues(alpha: 0.1), costTypeColor.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: costTypeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: costTypeColor),
                          ),
                          child: Text(
                            _miscCost!.costTypeLabel,
                            style: TextStyle(
                              color: costTypeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _miscCost!.formattedAmount,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _miscCost!.operationName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.business, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          _miscCost!.party,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Cost Information Card
            _buildInfoCard(
              title: 'Cost Information',
              icon: Icons.receipt_long,
              children: [
                _buildInfoRow('Date', DateFormat('dd MMM yyyy').format(DateTime.parse(_miscCost!.date))),
                _buildInfoRow('Cost Type', _miscCost!.costTypeLabel),
                _buildInfoRow('Party', _miscCost!.party),
                _buildInfoRow('Quantity', _miscCost!.formattedQuantity),
                _buildInfoRow('Rate', _miscCost!.formattedRate),
                _buildInfoRow('Total Amount', _miscCost!.formattedAmount, isHighlighted: true),
              ],
            ),

            const SizedBox(height: 16),

            // Additional Information Card
            _buildInfoCard(
              title: 'Additional Information',
              icon: Icons.info_outline,
              children: [
                if (_miscCost!.billNo != null && _miscCost!.billNo!.isNotEmpty)
                  _buildInfoRow('Bill Number', _miscCost!.billNo!),
                if (_miscCost!.remarks != null && _miscCost!.remarks!.isNotEmpty)
                  _buildInfoRow('Remarks', _miscCost!.remarks!, isMultiline: true),
              ],
            ),

            const SizedBox(height: 16),

            // Audit Information Card
            _buildInfoCard(
              title: 'Audit Information',
              icon: Icons.history,
              children: [
                _buildInfoRow('Created By', _miscCost!.createdByName ?? 'Unknown'),
                _buildInfoRow('Created At', DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(_miscCost!.createdAt))),
                _buildInfoRow('Updated At', DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(_miscCost!.updatedAt))),
              ],
            ),

            const SizedBox(height: 32),

            // Action Buttons
            if (canEdit) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/miscellaneous/${widget.costId}/edit'),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Cost'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _deleteCost,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isHighlighted = false,
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: isHighlighted 
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : EdgeInsets.zero,
              decoration: isHighlighted
                  ? BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    )
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                  color: isHighlighted ? AppColors.success : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 