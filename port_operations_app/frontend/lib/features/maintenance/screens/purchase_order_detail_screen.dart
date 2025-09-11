import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/models/purchase_order_model.dart';
import '../../../shared/models/work_order_model.dart';
import '../../../shared/models/user_model.dart';
import '../services/purchase_order_service.dart';
import '../services/work_order_service.dart';
import '../../auth/auth_service.dart';
import 'po_items_screen.dart';
import 'work_order_detail_screen.dart';
import 'create_purchase_order_screen.dart';
import 'dart:math' as math;

class PurchaseOrderDetailScreen extends ConsumerStatefulWidget {
  final PurchaseOrder purchaseOrder;

  const PurchaseOrderDetailScreen({
    super.key,
    required this.purchaseOrder,
  });

  @override
  ConsumerState<PurchaseOrderDetailScreen> createState() => _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends ConsumerState<PurchaseOrderDetailScreen> {
  late PurchaseOrder _purchaseOrder;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _purchaseOrder = widget.purchaseOrder;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_purchaseOrder.poId),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (user?.canManagePurchaseOrders == true)
            PopupMenuButton<String>(
              onSelected: (String action) {
                _handlePurchaseOrderAction(action, user!);
              },
              itemBuilder: (BuildContext context) => [
                if (_purchaseOrder.isOpen)
                  const PopupMenuItem(
                    value: 'close',
                    child: Text('Close Purchase Order'),
                  ),
                if (user?.canEnterBillNumbers == true)
                  const PopupMenuItem(
                    value: 'bill',
                    child: Text('Update Bill Number'),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Purchase Order'),
                ),
                const PopupMenuItem(
                  value: 'items',
                  child: Text('Manage Items'),
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
                  if (_purchaseOrder.hasDuplicateWarning)
                    _buildDuplicateWarningCard(),
                  if (_purchaseOrder.hasDuplicateWarning)
                    const SizedBox(height: 16),
                  _buildBasicInfoCard(),
                  const SizedBox(height: 16),
                  _buildVendorTargetCard(),
                  const SizedBox(height: 16),
                  _buildItemsCard(),
                  const SizedBox(height: 16),
                  _buildDetailsCard(),
                  if (_purchaseOrder.remarkText?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _buildRemarksCard(),
                  ],
                  if (_purchaseOrder.remarkAudio != null) ...[
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
    final statusColor = _purchaseOrder.isOpen ? Colors.blue : Colors.grey;
    
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
                _purchaseOrder.statusDisplay,
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
                    'Purchase Order Status',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _purchaseOrder.isOpen ? 'Active purchase order' : 'Completed purchase order',
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

  Widget _buildDuplicateWarningCard() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duplicate Warning',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Similar purchase order exists for this vendor/vehicle combination',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 14,
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
            Row(
              children: [
                const Text(
                  'Purchase Order Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (user?.canManagePurchaseOrders == true)
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatePurchaseOrderScreen(initialPurchaseOrder: _purchaseOrder),
                        ),
                      );
                      if (result == true) {
                        ref.invalidate(purchaseOrdersProvider('open'));
                      }
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Purchase Order ID', _purchaseOrder.poId),
            _buildInfoRow('Category', _purchaseOrder.categoryDisplay),
            _buildInfoRow('Target Type', _purchaseOrder.forStock ? 'For Stock' : 'For Vehicle'),
            if (_purchaseOrder.billNo != null)
              _buildInfoRow('Bill Number', _purchaseOrder.billNo!),
            _buildLinkManagementRow(user?.canManagePurchaseOrders == true),
          ],
        ),
      ),
    );
  }

  Future<void> _onEditPurchaseOrder() async {
    final categoryController = TextEditingController(text: _purchaseOrder.category);
    final remarkController = TextEditingController(text: _purchaseOrder.remarkText ?? '');
    final billController = TextEditingController(text: _purchaseOrder.billNo ?? '');
    final formKey = GlobalKey<FormState>();
    final categories = const ['engine','hydraulic','bushing','electrical','other'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Purchase Order'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: categoryController.text.isNotEmpty ? categoryController.text : null,
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => categoryController.text = v ?? _purchaseOrder.category,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Select category' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: remarkController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Remarks', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: billController,
                  decoration: const InputDecoration(labelText: 'Bill No. (optional)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      setState(() => _isLoading = true);
      final payload = {
        'category': categoryController.text,
        'remark_text': remarkController.text,
      };
      await ref.read(purchaseOrderServiceProvider).updatePurchaseOrder(_purchaseOrder.id!, payload);
      if ((billController.text).trim() != (_purchaseOrder.billNo ?? '')) {
        await ref.read(purchaseOrderServiceProvider).updateBillNumber(_purchaseOrder.id!, billController.text.trim());
      }
      ref.invalidate(purchaseOrdersProvider('open'));
      setState(() {
        _isLoading = false;
        _purchaseOrder = PurchaseOrder(
          id: _purchaseOrder.id,
          poId: _purchaseOrder.poId,
          vendor: _purchaseOrder.vendor,
          vendorName: _purchaseOrder.vendorName,
          vehicle: _purchaseOrder.vehicle,
          vehicleNumber: _purchaseOrder.vehicleNumber,
          vehicleOther: _purchaseOrder.vehicleOther,
          forStock: _purchaseOrder.forStock,
          category: categoryController.text,
          remarkText: remarkController.text,
          remarkAudio: _purchaseOrder.remarkAudio,
          status: _purchaseOrder.status,
          linkedWo: _purchaseOrder.linkedWo,
          linkedWoId: _purchaseOrder.linkedWoId,
          linkedWoIds: _purchaseOrder.linkedWoIds,
          billNo: billController.text.trim().isEmpty ? null : billController.text.trim(),
          duplicateWarning: _purchaseOrder.duplicateWarning,
          itemsCount: _purchaseOrder.itemsCount,
          totalAmount: _purchaseOrder.totalAmount,
          createdBy: _purchaseOrder.createdBy,
          createdByName: _purchaseOrder.createdByName,
          createdAt: _purchaseOrder.createdAt,
          updatedAt: _purchaseOrder.updatedAt,
        );
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase order updated')));
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  Widget _buildVendorTargetCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vendor & Target Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Vendor', _purchaseOrder.vendorName ?? 'Unknown'),
            _buildInfoRow('Target', _purchaseOrder.displayTarget),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: ref.read(purchaseOrderServiceProvider).getAudits(_purchaseOrder.id!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final audits = snapshot.data!;
                if (audits.isEmpty) return const SizedBox.shrink();
                final recent = audits.take(5).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _showAllAudits(context, audits),
                          child: const Text('View all'),
                        )
                      ],
                    ),
                    for (final a in recent)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              a['action'] == 'link' ? Icons.link : a['action'] == 'unlink' ? Icons.link_off : Icons.edit,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_auditLine(a))),
                            Text(_shortTime(a['created_at'])),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _auditLine(Map<String, dynamic> a) {
    final user = a['performed_by_name'] ?? 'Someone';
    final action = a['action'];
    if (action == 'link') return '$user linked ${a['related_entity_type']} ${a['related_entity_id']}';
    if (action == 'unlink') return '$user unlinked ${a['related_entity_type']} ${a['related_entity_id']}';
    if (action == 'update') return '$user updated this purchase order';
    return '$user did $action';
  }

  String _shortTime(String? iso) {
    if (iso == null) return '';
    return iso.substring(11, 16); // HH:MM
  }

  void _showAllAudits(BuildContext context, List<Map<String, dynamic>> audits) {
    String? actionFilter;
    String query = '';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filtered = audits.where((a) {
            final matchesAction = actionFilter == null || a['action'] == actionFilter;
            final text = (_auditLine(a) + (a['performed_by_name'] ?? '')).toLowerCase();
            final matchesQuery = text.contains(query.toLowerCase());
            return matchesAction && matchesQuery;
          }).toList();
          return AlertDialog(
            title: const Text('Activity'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      DropdownButton<String?>(
                        value: actionFilter,
                        hint: const Text('All actions'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: 'link', child: Text('Link')),
                          DropdownMenuItem(value: 'unlink', child: Text('Unlink')),
                          DropdownMenuItem(value: 'update', child: Text('Update')),
                        ],
                        onChanged: (v) => setState(() => actionFilter = v),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by user or text', isDense: true),
                          onChanged: (v) => setState(() => query = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => ListTile(
                        dense: true,
                        leading: Icon(
                          filtered[i]['action'] == 'link' ? Icons.link : filtered[i]['action'] == 'unlink' ? Icons.link_off : Icons.edit,
                          size: 18,
                        ),
                        title: Text(_auditLine(filtered[i])),
                        subtitle: Text('${filtered[i]['performed_by_name'] ?? '-'} • ${filtered[i]['created_at'] ?? ''}'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items & Costs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_purchaseOrder.isOpen)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => POItemsScreen(purchaseOrder: _purchaseOrder),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Manage'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Items Count', '${_purchaseOrder.itemsCount ?? 0} items'),
            if ((_purchaseOrder.totalAmount ?? 0) > 0)
              _buildInfoRow('Total Amount', '₹${(_purchaseOrder.totalAmount ?? 0).toStringAsFixed(2)}'),
            if ((_purchaseOrder.itemsCount ?? 0) == 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No items added yet. Add items to complete the purchase order.',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 14,
                        ),
                      ),
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

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Purchase Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Purchase Category', _purchaseOrder.categoryDisplay),
            _buildInfoRow('Delivery Timeline', 'TBD'), // Could be added to model
            _buildInfoRow('Priority', 'Normal'), // Default priority
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
              'Purchase Description',
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
                _purchaseOrder.remarkText!,
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
            _buildInfoRow('Created By', _purchaseOrder.createdByName ?? 'Unknown'),
            _buildInfoRow('Created On', _purchaseOrder.createdAt ?? 'Unknown'),
            if (_purchaseOrder.updatedAt != null && _purchaseOrder.updatedAt != _purchaseOrder.createdAt)
              _buildInfoRow('Last Updated', _purchaseOrder.updatedAt!),
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

  Widget _buildLinkManagementRow(bool canManage) {
    final hasLink = (_purchaseOrder.linkedWoId != null) || ((_purchaseOrder.linkedWoIds ?? []).isNotEmpty);
    final ids = <String>[];
    if (_purchaseOrder.linkedWoId != null) ids.add(_purchaseOrder.linkedWoId!);
    if (_purchaseOrder.linkedWoIds != null) ids.addAll(_purchaseOrder.linkedWoIds!);

    final wosAsync = ref.watch(workOrdersProvider('open'));

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Linked WOs', style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              if (canManage)
                wosAsync.when(
                  data: (wos) {
                    final availableCount = wos.where((w) => w.status == 'open').length; // Count all open WOs (since one WO can have multiple POs)
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
                          onPressed: _onLinkWo,
                          icon: const Icon(Icons.link, size: 16),
                          label: const Text('Link WO'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        ),
                      ],
                    );
                  },
                  loading: () => TextButton.icon(
                    onPressed: _onLinkWo,
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('Link WO'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                  error: (_, __) => TextButton.icon(
                    onPressed: _onLinkWo,
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('Link WO'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasLink) const Text('None', style: TextStyle(color: Colors.grey)),
          if (hasLink)
            wosAsync.when(
              data: (wos) {
                final items = ids.map((woId) {
                  final match = wos.where((w) => w.woId == woId).toList();
                  final wo = match.isNotEmpty ? match.first : null;
                  final subtitle = wo != null
                      ? '${wo.vendorName ?? '-'} • ${wo.displayVehicle}'
                      : 'Tap to open';
                  return _LinkedInfoChip(
                    title: woId,
                    subtitle: subtitle,
                    leadingIcon: Icons.home_repair_service,
                    onTap: () => _openWoById(woId),
                    onRemove: canManage ? () => _unlinkWoById(woId) : null,
                  );
                }).toList();
                return Wrap(spacing: 8, runSpacing: 8, children: items);
              },
              loading: () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ids.map((woId) => _LinkedInfoChip(
                  title: woId,
                  subtitle: 'Loading...',
                  leadingIcon: Icons.home_repair_service,
                  onTap: () {},
                )).toList(),
              ),
              error: (_, __) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ids.map((woId) => _LinkedInfoChip(
                  title: woId,
                  subtitle: 'Tap to open',
                  leadingIcon: Icons.home_repair_service,
                  onTap: () => _openWoById(woId),
                  onRemove: canManage ? () => _unlinkWoById(woId) : null,
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onLinkWo() async {
    try {
      final wos = await ref.read(workOrdersProvider('open').future);
      // Show all open WOs (one WO can have multiple POs)
      final candidates = wos.where((w) => w.status == 'open').toList();
      if (candidates.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No available open WOs to link')),
          );
        }
        return;
      }

      // Dialog state
      WorkOrder? selected;
      String query = '';
      String sort = 'date_desc';
      int pageSize = 50;
      int page = 1;

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              List<WorkOrder> filtered = candidates
                  .where((wo) =>
                      wo.woId.toLowerCase().contains(query.toLowerCase()) ||
                      (wo.vendorName ?? '').toLowerCase().contains(query.toLowerCase()) ||
                      wo.displayVehicle.toLowerCase().contains(query.toLowerCase()))
                  .toList();

              // Sort
              filtered.sort((a, b) {
                switch (sort) {
                  case 'vendor_asc':
                    return (a.vendorName ?? '').compareTo(b.vendorName ?? '');
                  case 'vendor_desc':
                    return (b.vendorName ?? '').compareTo(a.vendorName ?? '');
                  case 'date_asc':
                    return (a.id ?? 0).compareTo(b.id ?? 0);
                  case 'date_desc':
                  default:
                    return (b.id ?? 0).compareTo(a.id ?? 0);
                }
              });

              final total = filtered.length;
              final end = (page * pageSize).clamp(0, total);
              final items = filtered.take(end).toList();

              return AlertDialog(
                title: const Text('Link Work Order'),
                content: SizedBox(
                  width: math.min(420.0, MediaQuery.of(context).size.width - 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search by WO ID, vendor, vehicle',
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => query = v),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Sort:', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          DropdownButton<String>(
                            value: sort,
                            items: const [
                              DropdownMenuItem(value: 'date_desc', child: Text('Date ↓')),
                              DropdownMenuItem(value: 'date_asc', child: Text('Date ↑')),
                              DropdownMenuItem(value: 'vendor_asc', child: Text('Vendor A→Z')),
                              DropdownMenuItem(value: 'vendor_desc', child: Text('Vendor Z→A')),
                            ],
                            onChanged: (v) => setState(() => sort = v ?? 'date_desc'),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                            child: Text('${items.length}/$total'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final wo = items[index];
                            return RadioListTile<WorkOrder>(
                              value: wo,
                              groupValue: selected,
                              onChanged: (v) => setState(() => selected = v),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          wo.woId,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Chip(label: Text(wo.statusDisplay), visualDensity: VisualDensity.compact),
                                    ],
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${wo.vendorName ?? '-'} • ${wo.displayVehicle}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ),
                      if (items.length < total)
                        TextButton(
                          onPressed: () => setState(() => page += 1),
                          child: const Text('Load more'),
                        ),
                    ],
                  ),
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
      ).then((value) => selected = value as WorkOrder?);

      if (selected == null) return;

      setState(() => _isLoading = true);
      await ref.read(purchaseOrderServiceProvider).linkWorkOrder(_purchaseOrder.id!, selected!.id!);

      // Cross-refresh: invalidate both PO and WO lists
      ref.invalidate(purchaseOrdersProvider('open'));
      ref.invalidate(workOrdersProvider('open'));

      setState(() {
        _isLoading = false;
        final updatedIds = <String>[...(_purchaseOrder.linkedWoIds ?? [])];
        updatedIds.add(selected!.woId);
        _purchaseOrder = PurchaseOrder(
          id: _purchaseOrder.id,
          poId: _purchaseOrder.poId,
          vendor: _purchaseOrder.vendor,
          vendorName: _purchaseOrder.vendorName,
          vehicle: _purchaseOrder.vehicle,
          vehicleNumber: _purchaseOrder.vehicleNumber,
          vehicleOther: _purchaseOrder.vehicleOther,
          forStock: _purchaseOrder.forStock,
          category: _purchaseOrder.category,
          remarkText: _purchaseOrder.remarkText,
          remarkAudio: _purchaseOrder.remarkAudio,
          status: _purchaseOrder.status,
          linkedWo: _purchaseOrder.linkedWo,
          linkedWoId: _purchaseOrder.linkedWoId,
          linkedWoIds: updatedIds,
          billNo: _purchaseOrder.billNo,
          duplicateWarning: _purchaseOrder.duplicateWarning,
          itemsCount: _purchaseOrder.itemsCount,
          totalAmount: _purchaseOrder.totalAmount,
          createdBy: _purchaseOrder.createdBy,
          createdByName: _purchaseOrder.createdByName,
          createdAt: _purchaseOrder.createdAt,
          updatedAt: _purchaseOrder.updatedAt,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WO linked successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to link work order: $e')),
        );
      }
    }
  }

  Future<void> _openWoById(String woId) async {
    try {
      final wos = await ref.read(workOrdersProvider('open').future);
      final match = wos.firstWhere((w) => w.woId == woId, orElse: () => wos.isNotEmpty ? wos.first : throw Exception('WO not found'));
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => WorkOrderDetailScreen(workOrder: match)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open WO')));
    }
  }

  Future<void> _unlinkWoById(String woId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Work Order'),
        content: Text('Are you sure you want to unlink WO $woId from this purchase order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unlink')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final wos = await ref.read(workOrdersProvider('open').future);
      final selected = wos.firstWhere((w) => w.woId == woId);
      setState(() => _isLoading = true);
      await ref.read(purchaseOrderServiceProvider).unlinkWorkOrder(_purchaseOrder.id!, selected.id!);
      ref.invalidate(purchaseOrdersProvider('open'));
      ref.invalidate(workOrdersProvider('open'));

      setState(() {
        _isLoading = false;
        final updatedIds = <String>[...(_purchaseOrder.linkedWoIds ?? [])];
        updatedIds.remove(woId);
        _purchaseOrder = PurchaseOrder(
          id: _purchaseOrder.id,
          poId: _purchaseOrder.poId,
          vendor: _purchaseOrder.vendor,
          vendorName: _purchaseOrder.vendorName,
          vehicle: _purchaseOrder.vehicle,
          vehicleNumber: _purchaseOrder.vehicleNumber,
          vehicleOther: _purchaseOrder.vehicleOther,
          forStock: _purchaseOrder.forStock,
          category: _purchaseOrder.category,
          remarkText: _purchaseOrder.remarkText,
          remarkAudio: _purchaseOrder.remarkAudio,
          status: _purchaseOrder.status,
          linkedWo: _purchaseOrder.linkedWo,
          linkedWoId: _purchaseOrder.linkedWoId == woId ? null : _purchaseOrder.linkedWoId,
          linkedWoIds: updatedIds,
          billNo: _purchaseOrder.billNo,
          duplicateWarning: _purchaseOrder.duplicateWarning,
          itemsCount: _purchaseOrder.itemsCount,
          totalAmount: _purchaseOrder.totalAmount,
          createdBy: _purchaseOrder.createdBy,
          createdByName: _purchaseOrder.createdByName,
          createdAt: _purchaseOrder.createdAt,
          updatedAt: _purchaseOrder.updatedAt,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WO unlinked successfully')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to unlink: $e')));
      }
    }
  }

  void _handlePurchaseOrderAction(String action, User user) {
    switch (action) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit Purchase Order - Coming Soon!')),
        );
        break;
      case 'close':
        _closePurchaseOrder();
        break;
      case 'bill':
        _updateBillNumber();
        break;
      case 'items':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => POItemsScreen(purchaseOrder: _purchaseOrder),
          ),
        );
        break;
    }
  }

  void _closePurchaseOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Purchase Order'),
        content: Text('Are you sure you want to close purchase order ${_purchaseOrder.poId}?'),
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
                final service = ref.read(purchaseOrderServiceProvider);
                await service.closePurchaseOrder(_purchaseOrder.id!);
                
                setState(() {
                  _purchaseOrder = PurchaseOrder(
                    id: _purchaseOrder.id,
                    poId: _purchaseOrder.poId,
                    vendor: _purchaseOrder.vendor,
                    vendorName: _purchaseOrder.vendorName,
                    vehicle: _purchaseOrder.vehicle,
                    vehicleNumber: _purchaseOrder.vehicleNumber,
                    vehicleOther: _purchaseOrder.vehicleOther,
                    forStock: _purchaseOrder.forStock,
                    category: _purchaseOrder.category,
                    remarkText: _purchaseOrder.remarkText,
                    remarkAudio: _purchaseOrder.remarkAudio,
                    status: 'closed',
                    linkedWo: _purchaseOrder.linkedWo,
                    linkedWoId: _purchaseOrder.linkedWoId,
                    billNo: _purchaseOrder.billNo,
                    duplicateWarning: _purchaseOrder.duplicateWarning,
                    itemsCount: _purchaseOrder.itemsCount,
                    totalAmount: _purchaseOrder.totalAmount,
                    createdBy: _purchaseOrder.createdBy,
                    createdByName: _purchaseOrder.createdByName,
                    createdAt: _purchaseOrder.createdAt,
                    updatedAt: _purchaseOrder.updatedAt,
                  );
                  _isLoading = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchase order closed successfully')),
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
    final controller = TextEditingController(text: _purchaseOrder.billNo);
    
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
                final service = ref.read(purchaseOrderServiceProvider);
                await service.updateBillNumber(_purchaseOrder.id!, billNo);
                
                setState(() {
                  _purchaseOrder = PurchaseOrder(
                    id: _purchaseOrder.id,
                    poId: _purchaseOrder.poId,
                    vendor: _purchaseOrder.vendor,
                    vendorName: _purchaseOrder.vendorName,
                    vehicle: _purchaseOrder.vehicle,
                    vehicleNumber: _purchaseOrder.vehicleNumber,
                    vehicleOther: _purchaseOrder.vehicleOther,
                    forStock: _purchaseOrder.forStock,
                    category: _purchaseOrder.category,
                    remarkText: _purchaseOrder.remarkText,
                    remarkAudio: _purchaseOrder.remarkAudio,
                    status: _purchaseOrder.status,
                    linkedWo: _purchaseOrder.linkedWo,
                    linkedWoId: _purchaseOrder.linkedWoId,
                    billNo: billNo,
                    duplicateWarning: _purchaseOrder.duplicateWarning,
                    itemsCount: _purchaseOrder.itemsCount,
                    totalAmount: _purchaseOrder.totalAmount,
                    createdBy: _purchaseOrder.createdBy,
                    createdByName: _purchaseOrder.createdByName,
                    createdAt: _purchaseOrder.createdAt,
                    updatedAt: _purchaseOrder.updatedAt,
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
                InkWell(onTap: onRemove!, child: const Icon(Icons.close, size: 16)),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 