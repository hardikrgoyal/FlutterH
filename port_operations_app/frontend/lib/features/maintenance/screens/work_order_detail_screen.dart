import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/models/work_order_model.dart';
import '../../../shared/models/purchase_order_model.dart';
import '../../../shared/models/user_model.dart';
import '../services/work_order_service.dart';
import '../services/purchase_order_service.dart';
import '../../auth/auth_service.dart';
import 'purchase_order_detail_screen.dart';

class WorkOrderDetailScreen extends ConsumerStatefulWidget {
  final WorkOrder workOrder;

  const WorkOrderDetailScreen({
    super.key,
    required this.workOrder,
  });

  @override
  ConsumerState<WorkOrderDetailScreen> createState() => _WorkOrderDetailScreenState();
}

class _WorkOrderDetailScreenState extends ConsumerState<WorkOrderDetailScreen> {
  late WorkOrder _workOrder;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _workOrder = widget.workOrder;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_workOrder.woId),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (user?.canManageWorkOrders == true)
            PopupMenuButton<String>(
              onSelected: (String action) {
                _handleWorkOrderAction(action, user!);
              },
              itemBuilder: (BuildContext context) => [
                if (_workOrder.isOpen)
                  const PopupMenuItem(
                    value: 'close',
                    child: Text('Close Work Order'),
                  ),
                if (user?.canEnterBillNumbers == true)
                  const PopupMenuItem(
                    value: 'bill',
                    child: Text('Update Bill Number'),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Work Order'),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildBasicInfoCard(),
                  const SizedBox(height: 16),
                  _buildVendorVehicleCard(),
                  const SizedBox(height: 16),
                  _buildDetailsCard(),
                  if (_workOrder.remarkText?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _buildRemarksCard(),
                  ],
                  if (_workOrder.remarkAudio != null) ...[
                    const SizedBox(height: 16),
                    _buildAudioCard(),
                  ],
                  const SizedBox(height: 16),
                  _buildMetadataCard(),
                  const SizedBox(height: 80), // Extra space for content
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _workOrder.isOpen ? Colors.green : Colors.grey;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _workOrder.statusDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Work Order Status',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _workOrder.isOpen ? 'Active work order' : 'Completed work order',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  Widget _buildBasicInfoCard() {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Work Order Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Work Order ID', _workOrder.woId),
            _buildInfoRow('Category', _workOrder.categoryDisplay),
            if (_workOrder.billNo != null)
              _buildInfoRow('Bill Number', _workOrder.billNo!),
            _buildLinkManagementRow(user?.canManageWorkOrders == true),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkManagementRow(bool canManage) {
    final hasLink = (_workOrder.linkedPoId != null) || ((_workOrder.linkedPoIds ?? []).isNotEmpty);
    final ids = <String>[];
    if (_workOrder.linkedPoId != null) ids.add(_workOrder.linkedPoId!);
    if (_workOrder.linkedPoIds != null) ids.addAll(_workOrder.linkedPoIds!);

    final posAsync = ref.watch(purchaseOrdersProvider('open'));

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Linked POs', style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              if (canManage)
                posAsync.when(
                  data: (pos) {
                    final availableCount = pos.where((p) => p.linkedWoIds == null || p.linkedWoIds!.isEmpty).length;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                          child: Text('$availableCount', style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        TextButton.icon(
                          onPressed: _onLinkPo,
                          icon: const Icon(Icons.link, size: 16),
                          label: const Text('Link PO'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        ),
                      ],
                    );
                  },
                  loading: () => TextButton.icon(
                    onPressed: _onLinkPo,
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('Link PO'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                  error: (_, __) => TextButton.icon(
                    onPressed: _onLinkPo,
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('Link PO'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasLink) const Text('None', style: TextStyle(color: Colors.grey)),
          if (hasLink)
            posAsync.when(
              data: (pos) {
                final items = ids.map((poId) {
                  final match = pos.where((p) => p.poId == poId).toList();
                  final po = match.isNotEmpty ? match.first : null;
                  final subtitle = po != null
                      ? '${po.vendorName ?? '-'} • ${po.displayTarget}${po.totalAmount != null ? ' • ₹${po.totalAmount!.toStringAsFixed(0)}' : ''}'
                      : 'Tap to open';
                  return _LinkedInfoChip(
                    title: poId,
                    subtitle: subtitle,
                    leadingIcon: Icons.receipt_long,
                    onTap: () => _openPoById(poId),
                    onRemove: canManage ? () => _unlinkPoById(poId) : null,
                  );
                }).toList();
                return Wrap(spacing: 8, runSpacing: 8, children: items);
              },
              loading: () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ids.map((poId) => _LinkedInfoChip(
                  title: poId,
                  subtitle: 'Loading...',
                  leadingIcon: Icons.receipt_long,
                  onTap: () {},
                )).toList(),
              ),
              error: (_, __) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ids.map((poId) => _LinkedInfoChip(
                  title: poId,
                  subtitle: 'Tap to open',
                  leadingIcon: Icons.receipt_long,
                  onTap: () => _openPoById(poId),
                  onRemove: canManage ? () => _unlinkPoById(poId) : null,
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onLinkPo() async {
    try {
      final pos = await ref.read(purchaseOrdersProvider('open').future);
      // Only POs that are not linked to any WO
      final available = pos.where((p) => p.linkedWoIds == null || p.linkedWoIds!.isEmpty).toList();
      if (available.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No available open POs to link')),
          );
        }
        return;
      }

      PurchaseOrder? selected;
      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Link Purchase Order'),
                content: DropdownButtonFormField<PurchaseOrder>(
                  value: selected,
                  decoration: const InputDecoration(
                    labelText: 'Select PO',
                    border: OutlineInputBorder(),
                  ),
                  items: available.map((po) => DropdownMenuItem<PurchaseOrder>(
                    value: po,
                    child: Text('${po.poId} - ${po.displayTarget}'),
                  )).toList(),
                  onChanged: (value) => setState(() => selected = value),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: selected == null ? null : () => Navigator.pop(context, selected),
                    child: const Text('Link'),
                  ),
                ],
              );
            },
          );
        },
      ).then((value) => selected = value as PurchaseOrder?);

      if (selected == null) return;

      setState(() => _isLoading = true);
      final service = ref.read(workOrderServiceProvider);
      await service.linkPurchaseOrder(_workOrder.id!, selected!.id!);

      // Cross-refresh: invalidate both WO and PO lists
      ref.invalidate(workOrdersProvider('open'));
      ref.invalidate(purchaseOrdersProvider('open'));

      setState(() {
        _isLoading = false;
        final updatedIds = <String>[...(_workOrder.linkedPoIds ?? [])];
        updatedIds.add(selected!.poId);
        _workOrder = WorkOrder(
          id: _workOrder.id,
          woId: _workOrder.woId,
          vendor: _workOrder.vendor,
          vendorName: _workOrder.vendorName,
          vehicle: _workOrder.vehicle,
          vehicleNumber: _workOrder.vehicleNumber,
          vehicleOther: _workOrder.vehicleOther,
          category: _workOrder.category,
          remarkText: _workOrder.remarkText,
          remarkAudio: _workOrder.remarkAudio,
          status: _workOrder.status,
          linkedPo: _workOrder.linkedPo,
          linkedPoId: _workOrder.linkedPoId,
          linkedPoIds: updatedIds,
          billNo: _workOrder.billNo,
          createdBy: _workOrder.createdBy,
          createdByName: _workOrder.createdByName,
          createdAt: _workOrder.createdAt,
          updatedAt: _workOrder.updatedAt,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PO linked successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to link PO: $e')),
        );
      }
    }
  }

  Future<void> _openPoById(String poId) async {
    try {
      // Try to locate PO from cached provider list
      final pos = await ref.read(purchaseOrdersProvider('open').future);
      final match = pos.firstWhere((p) => p.poId == poId, orElse: () => pos.firstWhere((p) => p.poId == poId, orElse: () => pos.isNotEmpty ? pos.first : throw Exception('PO not found')));
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => PurchaseOrderDetailScreen(purchaseOrder: match)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open PO')));
    }
  }

  Future<void> _unlinkPoById(String poId) async {
    try {
      final pos = await ref.read(purchaseOrdersProvider('open').future);
      final selected = pos.firstWhere((p) => p.poId == poId);
      setState(() => _isLoading = true);
      await ref.read(workOrderServiceProvider).unlinkPurchaseOrder(_workOrder.id!, selected.id!);
      ref.invalidate(workOrdersProvider('open'));
      ref.invalidate(purchaseOrdersProvider('open'));

      setState(() {
        _isLoading = false;
        final updatedIds = <String>[...(_workOrder.linkedPoIds ?? [])];
        updatedIds.remove(poId);
        _workOrder = WorkOrder(
          id: _workOrder.id,
          woId: _workOrder.woId,
          vendor: _workOrder.vendor,
          vendorName: _workOrder.vendorName,
          vehicle: _workOrder.vehicle,
          vehicleNumber: _workOrder.vehicleNumber,
          vehicleOther: _workOrder.vehicleOther,
          category: _workOrder.category,
          remarkText: _workOrder.remarkText,
          remarkAudio: _workOrder.remarkAudio,
          status: _workOrder.status,
          linkedPo: _workOrder.linkedPo,
          linkedPoId: _workOrder.linkedPoId == poId ? null : _workOrder.linkedPoId,
          linkedPoIds: updatedIds,
          billNo: _workOrder.billNo,
          createdBy: _workOrder.createdBy,
          createdByName: _workOrder.createdByName,
          createdAt: _workOrder.createdAt,
          updatedAt: _workOrder.updatedAt,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PO unlinked successfully')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to unlink: $e')));
      }
    }
  }

  Widget _buildVendorVehicleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vendor & Vehicle Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Vendor', _workOrder.vendorName ?? 'Unknown'),
            _buildInfoRow('Vehicle', _workOrder.displayVehicle),
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
            const Text(
              'Work Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Work Category', _workOrder.categoryDisplay),
            _buildInfoRow('Priority', 'Normal'), // Default priority
            _buildInfoRow('Estimated Cost', 'TBD'), // Could be calculated from linked PO
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
            const Text(
              'Work Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _workOrder.remarkText!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audio Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.audiotrack, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Audio note available',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement audio playback
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Audio playback - Coming Soon!')),
                      );
                    },
                    icon: Icon(Icons.play_arrow, color: Colors.blue[700]),
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
            const Text(
              'Creation Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Created By', _workOrder.createdByName ?? 'Unknown'),
            _buildInfoRow('Created On', _workOrder.createdAt ?? 'Unknown'),
            if (_workOrder.updatedAt != null && _workOrder.updatedAt != _workOrder.createdAt)
              _buildInfoRow('Last Updated', _workOrder.updatedAt!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleWorkOrderAction(String action, User user) {
    switch (action) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit Work Order - Coming Soon!')),
        );
        break;
      case 'close':
        _closeWorkOrder();
        break;
      case 'bill':
        _updateBillNumber();
        break;
    }
  }

  void _closeWorkOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Work Order'),
        content: Text('Are you sure you want to close work order ${_workOrder.woId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              try {
                final service = ref.read(workOrderServiceProvider);
                await service.closeWorkOrder(_workOrder.id!);
                
                setState(() {
                  _workOrder = WorkOrder(
                    id: _workOrder.id,
                    woId: _workOrder.woId,
                    vendor: _workOrder.vendor,
                    vendorName: _workOrder.vendorName,
                    vehicle: _workOrder.vehicle,
                    vehicleNumber: _workOrder.vehicleNumber,
                    vehicleOther: _workOrder.vehicleOther,
                    category: _workOrder.category,
                    remarkText: _workOrder.remarkText,
                    remarkAudio: _workOrder.remarkAudio,
                    status: 'closed',
                    linkedPo: _workOrder.linkedPo,
                    linkedPoId: _workOrder.linkedPoId,
                    billNo: _workOrder.billNo,
                    createdBy: _workOrder.createdBy,
                    createdByName: _workOrder.createdByName,
                    createdAt: _workOrder.createdAt,
                    updatedAt: _workOrder.updatedAt,
                  );
                  _isLoading = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Work order closed successfully')),
                );
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _updateBillNumber() {
    final controller = TextEditingController(text: _workOrder.billNo);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Bill Number'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Bill Number',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final billNo = controller.text.trim();
              if (billNo.isEmpty) return;
              
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              try {
                final service = ref.read(workOrderServiceProvider);
                await service.updateBillNumber(_workOrder.id!, billNo);
                
                setState(() {
                  _workOrder = WorkOrder(
                    id: _workOrder.id,
                    woId: _workOrder.woId,
                    vendor: _workOrder.vendor,
                    vendorName: _workOrder.vendorName,
                    vehicle: _workOrder.vehicle,
                    vehicleNumber: _workOrder.vehicleNumber,
                    vehicleOther: _workOrder.vehicleOther,
                    category: _workOrder.category,
                    remarkText: _workOrder.remarkText,
                    remarkAudio: _workOrder.remarkAudio,
                    status: _workOrder.status,
                    linkedPo: _workOrder.linkedPo,
                    linkedPoId: _workOrder.linkedPoId,
                    billNo: billNo,
                    createdBy: _workOrder.createdBy,
                    createdByName: _workOrder.createdByName,
                    createdAt: _workOrder.createdAt,
                    updatedAt: _workOrder.updatedAt,
                  );
                  _isLoading = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bill number updated successfully')),
                );
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
} 

class _LinkedChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  const _LinkedChip({required this.label, required this.onTap, this.onRemove});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Chip(
        label: Text(label),
        avatar: const Icon(Icons.receipt_long, size: 16),
        deleteIcon: onRemove != null ? const Icon(Icons.close) : null,
        onDeleted: onRemove,
      ),
    );
  }
}

class _LinkedInfoChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  const _LinkedInfoChip({required this.title, required this.subtitle, required this.leadingIcon, required this.onTap, this.onRemove});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[300]!)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(leadingIcon, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(subtitle, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  ],
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                InkWell(onTap: onRemove, child: const Icon(Icons.close, size: 16)),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 