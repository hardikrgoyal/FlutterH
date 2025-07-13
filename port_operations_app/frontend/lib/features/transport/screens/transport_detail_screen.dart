import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/models/transport_detail_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../services/transport_service.dart';
import '../../auth/auth_service.dart';

class TransportDetailScreen extends ConsumerStatefulWidget {
  final int transportId;

  const TransportDetailScreen({
    super.key,
    required this.transportId,
  });

  @override
  ConsumerState<TransportDetailScreen> createState() => _TransportDetailScreenState();
}

class _TransportDetailScreenState extends ConsumerState<TransportDetailScreen> {
  bool _isLoading = false;
  TransportDetail? _transport;

  @override
  void initState() {
    super.initState();
    _loadTransportDetail();
  }

  Future<void> _loadTransportDetail() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final transportService = ref.read(transportDetailProvider.notifier);
      final transport = await transportService.getTransportDetail(widget.transportId);

      if (!mounted) return;
      setState(() {
        _transport = transport;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load transport detail: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTransport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transport Detail'),
        content: const Text(
          'Are you sure you want to delete this transport detail? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final success = await ref.read(transportDetailProvider.notifier).deleteTransportDetail(widget.transportId);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transport detail deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else if (mounted) {
          final error = ref.read(transportDetailProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to delete transport detail'),
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

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if user has permission (only admin and manager)
    if (user.role != 'admin' && user.role != 'manager') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transport Detail'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        drawer: const AppDrawer(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Only administrators and managers can view transport details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Detail'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_transport != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/transport/${widget.transportId}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTransport,
            ),
          ],
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const LoadingWidget()
          : _transport == null
              ? const AppErrorWidget(
                  message: 'Transport detail not found',
                )
              : RefreshIndicator(
                  onRefresh: _loadTransportDetail,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 16),
                        _buildTransportDetailsCard(),
                        const SizedBox(height: 16),
                        _buildCostBreakdownCard(),
                        const SizedBox(height: 16),
                        _buildBillInformationCard(),
                        const SizedBox(height: 16),
                        if (_transport!.remarks != null && _transport!.remarks!.isNotEmpty)
                          _buildRemarksCard(),
                        if (_transport!.remarks != null && _transport!.remarks!.isNotEmpty)
                          const SizedBox(height: 16),
                        _buildAuditInformationCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    final contractTypeColor = _getContractTypeColor(_transport!.contractType);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [contractTypeColor.withOpacity(0.8), contractTypeColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(
                    _transport!.contractTypeDisplay ?? _getContractTypeLabel(_transport!.contractType),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM yyyy').format(DateTime.parse(_transport!.date)),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _transport!.displayTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.business, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _transport!.partyName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.work_outline, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _transport!.operationName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Transport Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Operation', _transport!.operationName, Icons.work_outline),
            _buildDetailRow('Date', DateFormat('dd MMM yyyy').format(DateTime.parse(_transport!.date)), Icons.calendar_today),
            _buildDetailRow('Vehicle Type', _transport!.vehicle, Icons.local_shipping),
            _buildDetailRow('Vehicle Number', _transport!.vehicleNumber, Icons.confirmation_number),
            _buildDetailRow('Contract Type', _transport!.contractTypeDisplay ?? _getContractTypeLabel(_transport!.contractType), Icons.description),
            _buildDetailRow('Party Name', _transport!.partyName, Icons.business),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBreakdownCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Cost Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Quantity', _transport!.quantity, Icons.scale),
            _buildDetailRow('Rate', '₹${_transport!.rate}', Icons.currency_rupee),
            const Divider(height: 24),
            _buildDetailRow(
              'Total Cost',
              _transport!.formattedCost,
              Icons.account_balance_wallet,
              valueStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillInformationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Bill Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Bill Number',
              _transport!.billNo ?? 'Not provided',
              Icons.receipt,
              valueStyle: _transport!.billNo != null
                  ? null
                  : const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Remarks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _transport!.remarks!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditInformationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Audit Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Created By',
              _transport!.createdByName ?? 'Unknown',
              Icons.person,
            ),
            _buildDetailRow(
              'Created At',
              DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(_transport!.createdAt)),
              Icons.access_time,
            ),
            _buildDetailRow(
              'Last Updated',
              DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(_transport!.updatedAt)),
              Icons.update,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: valueStyle ??
                  const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getContractTypeColor(String contractType) {
    switch (contractType) {
      case 'per_trip':
        return Colors.blue;
      case 'per_mt':
        return Colors.green;
      case 'daily':
        return Colors.orange;
      case 'lumpsum':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getContractTypeLabel(String contractType) {
    const labels = {
      'per_trip': 'Per Trip',
      'per_mt': 'Per MT',
      'daily': 'Daily',
      'lumpsum': 'Lumpsum',
    };
    return labels[contractType] ?? contractType;
  }
} 