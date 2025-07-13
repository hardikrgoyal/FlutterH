import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../models/equipment_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../services/equipment_service.dart';
import '../../auth/auth_service.dart';

class EquipmentDetailScreen extends ConsumerStatefulWidget {
  final int equipmentId;

  const EquipmentDetailScreen({
    super.key,
    required this.equipmentId,
  });

  @override
  ConsumerState<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends ConsumerState<EquipmentDetailScreen> {
  Equipment? _equipment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final equipmentService = ref.read(equipmentServiceProvider);
      _equipment = await equipmentService.getEquipment(widget.equipmentId);
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
        title: const Text('Equipment Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_equipment != null && user.canEditEquipment)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    context.push('/equipment/${widget.equipmentId}/edit');
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
      return const LoadingWidget(message: 'Loading equipment details...');
    }

    if (_error != null) {
      return AppErrorWidget(
        message: _error!,
        onRetry: _loadEquipment,
      );
    }

    if (_equipment == null) {
      return const AppErrorWidget(
        message: 'Equipment not found',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEquipment,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            const SizedBox(height: 16),
            _buildTimeTrackingCard(),
            const SizedBox(height: 16),
            _buildCostBreakdownCard(),
            if (_equipment!.comments?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _buildCommentsCard(),
            ],
            const SizedBox(height: 16),
            _buildInvoiceCard(),
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
          gradient: _getContractTypeGradient(_equipment!.contractType),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.truck,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _equipment!.displayTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_equipment!.contractType.toUpperCase()} • ${_equipment!.workTypeName}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _equipment!.isCompleted ? 'COMPLETED' : 'RUNNING',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
                      _equipment!.totalAmount != null 
                          ? '₹${NumberFormat('#,##0.00').format(double.parse(_equipment!.totalAmount!))}' 
                          : 'Pending',
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
                      'Duration',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      _equipment!.formattedDuration,
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
              'Equipment Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Operation',
              _equipment!.operationName,
              Icons.business,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Vehicle Type',
              _equipment!.vehicleTypeName,
              Icons.local_shipping,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Vehicle Number',
              _equipment!.vehicleNumber,
              Icons.confirmation_number,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Party',
              _equipment!.partyName,
              Icons.person,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Work Type',
              _equipment!.workTypeName,
              Icons.build,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Contract Type',
              _equipment!.contractType.toUpperCase(),
              Icons.assignment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTrackingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Tracking',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Start Time',
              _equipment!.formattedStartTime,
              Icons.play_arrow,
            ),
            if (_equipment!.endTime != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
                'End Time',
                _equipment!.formattedEndTime!,
                Icons.stop,
              ),
            ],
            const Divider(height: 24),
            _buildDetailRow(
              'Duration',
              _equipment!.formattedDuration,
              Icons.timer,
            ),
            if (_equipment!.quantity != null) ...[
              const Divider(height: 24),
              _buildQuantityDetailRow(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityDetailRow() {
    String quantityLabel = '';
    String quantityValue = '';
    IconData icon = Icons.info;
    
    switch (_equipment!.contractType.toLowerCase()) {
      case 'hours':
        quantityLabel = 'Hours Worked';
        quantityValue = '${_equipment!.quantity} Hours';
        icon = Icons.schedule;
        break;
      case 'shift':
        quantityLabel = 'Shifts Completed';
        quantityValue = '${_equipment!.quantity} Shifts';
        icon = Icons.access_time;
        break;
      case 'fixed':
        quantityLabel = 'Fixed Rate Job';
        quantityValue = 'Completed';
        icon = Icons.check_circle;
        break;
      case 'tonnes':
        quantityLabel = 'Tonnage Moved';
        quantityValue = '${_equipment!.quantity} Tonnes';
        icon = Icons.scale;
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return _buildDetailRow(quantityLabel, quantityValue, icon);
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
                  if (_equipment!.quantity != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quantity:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          '${_equipment!.quantity}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  if (user.canAccessCostDetails) ...[
                    if (_equipment!.quantity != null) const SizedBox(height: 8),
                    if (_equipment!.rate != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rate:',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            '₹${NumberFormat('#,##0.00').format(double.parse(_equipment!.rate!))}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    if (_equipment!.totalAmount != null) ...[
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
                            '₹${NumberFormat('#,##0.00').format(double.parse(_equipment!.totalAmount!))}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments',
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
                _equipment!.comments!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard() {
    final user = ref.read(authStateProvider).user!;
    
    if (!user.canAccessCostDetails) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Invoice Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
                  _buildDetailRow(
                    'Invoice Number',
                    _equipment!.invoiceNumber?.isNotEmpty == true 
                        ? _equipment!.invoiceNumber! 
                        : 'Not provided',
                    Icons.confirmation_number,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    'Invoice Date',
                    _equipment!.invoiceDate != null 
                        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(_equipment!.invoiceDate!))
                        : 'Not provided',
                    Icons.calendar_today,
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.receipt,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Invoice Status:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getInvoiceStatusColor(_equipment!.invoiceStatus),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _equipment!.invoiceStatus.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
              'Audit Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Created By',
              _equipment!.createdByName,
              Icons.person_add,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Created At',
              DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.parse(_equipment!.createdAt)),
              Icons.schedule,
            ),
            if (_equipment!.endedByName != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
                'Ended By',
                _equipment!.endedByName!,
                Icons.person,
              ),
            ],
            const Divider(height: 24),
            _buildDetailRow(
              'Updated At',
              DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.parse(_equipment!.updatedAt)),
              Icons.update,
            ),
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
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  LinearGradient _getContractTypeGradient(String contractType) {
    switch (contractType.toLowerCase()) {
      case 'hours':
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'shift':
        return const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'tonnes':
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'fixed':
        return const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF607D8B), Color(0xFF455A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getInvoiceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'received':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'not_applicable':
        return AppColors.grey400;
      default:
        return AppColors.grey400;
    }
  }

  Future<void> _showDeleteDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Equipment'),
        content: const Text(
          'Are you sure you want to delete this equipment record? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        final equipmentService = ref.read(equipmentServiceProvider);
        await equipmentService.deleteEquipment(widget.equipmentId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Equipment deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(); // Go back to previous screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete equipment: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
} 