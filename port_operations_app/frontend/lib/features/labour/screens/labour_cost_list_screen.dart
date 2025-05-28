import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/models/labour_cost_model.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../labour_service.dart';
import '../../auth/auth_service.dart';

class LabourCostListScreen extends ConsumerStatefulWidget {
  final int? operationId;

  const LabourCostListScreen({
    super.key,
    this.operationId,
  });

  @override
  ConsumerState<LabourCostListScreen> createState() => _LabourCostListScreenState();
}

class _LabourCostListScreenState extends ConsumerState<LabourCostListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLabourType;
  bool? _selectedInvoiceStatus;
  List<LabourCost> _filteredLabourCosts = [];
  List<LabourCost> _allLabourCosts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLabourCosts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadLabourCosts() {
    ref.read(labourCostProvider.notifier).loadLabourCosts(
      operationId: widget.operationId,
      refresh: true,
    );
  }

  void _filterLabourCosts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLabourCosts = _allLabourCosts.where((labourCost) {
        final matchesSearch = query.isEmpty || _matchesSearchQuery(labourCost, query);

        final matchesType = _selectedLabourType == null ||
            labourCost.labourType == _selectedLabourType;

        final matchesInvoiceStatus = _selectedInvoiceStatus == null ||
            labourCost.invoiceReceived == _selectedInvoiceStatus;

        return matchesSearch && matchesType && matchesInvoiceStatus;
      }).toList();
    });
  }

  bool _matchesSearchQuery(LabourCost labourCost, String query) {
    return (labourCost.contractorName?.toLowerCase().contains(query) == true) ||
        labourCost.labourTypeDisplay.toLowerCase().contains(query) ||
        labourCost.workTypeDisplay.toLowerCase().contains(query) ||
        (labourCost.operationName?.toLowerCase().contains(query) == true) ||
        (labourCost.invoiceNumber?.toLowerCase().contains(query) == true) ||
        (labourCost.amount?.toString().contains(query) == true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final labourCostState = ref.watch(labourCostProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.operationId != null 
            ? 'Operation Labour Costs' 
            : 'Labour Costs'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLabourCosts,
          ),
          if (user.canManageLabourCosts)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                context.push('/labour/new', extra: widget.operationId);
              },
            ),
        ],
      ),
      drawer: widget.operationId == null ? const AppDrawer() : null,
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: labourCostState.when(
              data: (labourCosts) {
                _allLabourCosts = labourCosts;
                
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _filterLabourCosts();
                });
                
                final displayList = _filteredLabourCosts.isEmpty && 
                    _searchController.text.isEmpty && 
                    _selectedLabourType == null && 
                    _selectedInvoiceStatus == null
                    ? labourCosts 
                    : _filteredLabourCosts;
                    
                return _buildLabourCostList(displayList);
              },
              loading: () => const LoadingWidget(),
              error: (error, stack) => AppErrorWidget(
                message: error.toString(),
                onRetry: _loadLabourCosts,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search labour costs...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _filterLabourCosts(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLabourType,
                    decoration: const InputDecoration(
                      labelText: 'Labour Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...LabourCost.labourTypeChoices.map((choice) =>
                        DropdownMenuItem<String>(
                          value: choice['value'],
                          child: Text(choice['label']!),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLabourType = value;
                      });
                      _filterLabourCosts();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<bool?>(
                    value: _selectedInvoiceStatus,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<bool?>(
                        value: null,
                        child: Text('All Invoices'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: true,
                        child: Text('Received'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: false,
                        child: Text('Pending'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedInvoiceStatus = value;
                      });
                      _filterLabourCosts();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabourCostList(List<LabourCost> labourCosts) {
    if (labourCosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MdiIcons.accountGroup,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'No labour costs found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add labour costs to track workforce expenses',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadLabourCosts(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: labourCosts.length,
        itemBuilder: (context, index) {
          final labourCost = labourCosts[index];
          return _buildLabourCostCard(labourCost);
        },
      ),
    );
  }

  Widget _buildLabourCostCard(LabourCost labourCost) {
    final user = ref.read(authStateProvider).user!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/labour/${labourCost.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getLabourTypeColor(labourCost.labourType),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      labourCost.labourTypeDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      labourCost.workTypeDisplay,
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getInvoiceStatusColor(labourCost.invoiceReceived).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getInvoiceStatusIcon(labourCost.invoiceReceived),
                          size: 12,
                          color: _getInvoiceStatusColor(labourCost.invoiceReceived),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          labourCost.invoiceStatusDisplay,
                          style: TextStyle(
                            color: _getInvoiceStatusColor(labourCost.invoiceReceived),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (user.canEditLabourCosts)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            context.push('/labour/${labourCost.id}/edit');
                            break;
                          case 'delete':
                            _showDeleteDialog(labourCost);
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
              const SizedBox(height: 12),
              Text(
                labourCost.contractorName ?? 'Unknown Contractor',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (labourCost.operationName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Operation: ${labourCost.operationName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(labourCost.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  const Spacer(),
                  if (user.canAccessCostDetails)
                    Text(
                      '₹${NumberFormat('#,##0.00').format(labourCost.amount ?? labourCost.calculatedAmount)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'Count/Tonnage',
                      '${labourCost.labourCountTonnage}',
                      Icons.group,
                    ),
                  ),
                  if (user.canAccessCostDetails) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        'Rate',
                        '₹${NumberFormat('#,##0.00').format(labourCost.rate ?? 0)}',
                        Icons.currency_rupee,
                      ),
                    ),
                  ],
                ],
              ),
              if (labourCost.remarks?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    labourCost.remarks!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              if (labourCost.hasInvoiceInfo) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getInvoiceStatusColor(labourCost.invoiceReceived).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getInvoiceStatusColor(labourCost.invoiceReceived).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt,
                        size: 16,
                        color: _getInvoiceStatusColor(labourCost.invoiceReceived),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoice: ${labourCost.invoiceNumber}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getInvoiceStatusColor(labourCost.invoiceReceived),
                              ),
                            ),
                            if (labourCost.invoiceDate != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Date: ${DateFormat('MMM dd, yyyy').format(labourCost.invoiceDate!)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _getInvoiceStatusColor(labourCost.invoiceReceived),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.textHint,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLabourTypeColor(String labourType) {
    switch (labourType) {
      case 'casual':
        return AppColors.info;
      case 'skilled':
        return AppColors.primary;
      case 'operator':
        return AppColors.warning;
      case 'supervisor':
        return AppColors.success;
      case 'others':
        return AppColors.accent;
      default:
        return AppColors.grey400;
    }
  }

  Color _getInvoiceStatusColor(bool? invoiceReceived) {
    if (invoiceReceived == true) {
      return AppColors.success;
    } else {
      return AppColors.warning;
    }
  }

  IconData _getInvoiceStatusIcon(bool? invoiceReceived) {
    if (invoiceReceived == true) {
      return Icons.check_circle;
    } else {
      return Icons.pending;
    }
  }

  void _showDeleteDialog(LabourCost labourCost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Labour Cost'),
        content: Text(
          'Are you sure you want to delete the labour cost for ${labourCost.contractorName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteLabourCost(labourCost);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteLabourCost(LabourCost labourCost) async {
    try {
      await ref.read(labourCostProvider.notifier).deleteLabourCost(labourCost.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Labour cost deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
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