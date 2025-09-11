import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/models/work_order_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../services/work_order_service.dart';
import '../services/purchase_order_service.dart';
import '../../auth/auth_service.dart';
import 'create_work_order_screen.dart';
import 'work_order_detail_screen.dart';

class WorkOrdersScreen extends ConsumerStatefulWidget {
  const WorkOrdersScreen({super.key});

  @override
  ConsumerState<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends ConsumerState<WorkOrdersScreen> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Work Orders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String value) {
              setState(() {
                _selectedStatus = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: 'open',
                child: Text('Open'),
              ),
              const PopupMenuItem(
                value: 'closed',
                child: Text('Closed'),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(user),
      floatingActionButton: user?.canCreateWorkOrders == true
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateWorkOrderScreen(),
                  ),
                ).then((result) {
                  if (result == true) {
                    // Refresh the list after creating
                    ref.invalidate(workOrdersProvider(_selectedStatus));
                  }
                });
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(User? user) {
    final workOrdersAsync = ref.watch(workOrdersProvider(_selectedStatus));
    final purchaseOrdersAsync = ref.watch(purchaseOrdersProvider('all'));

    return workOrdersAsync.when(
      data: (workOrders) => purchaseOrdersAsync.when(
        data: (purchaseOrders) {
          final poById = {for (var po in purchaseOrders) po.poId: po};
          return _buildWorkOrdersList(workOrders, user, poById);
        },
        loading: () => const LoadingWidget(),
        error: (_, __) => _buildWorkOrdersList(workOrders, user, const {}),
      ),
      loading: () => const LoadingWidget(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${error.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(workOrdersProvider(_selectedStatus)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkOrdersList(List<WorkOrder> workOrders, User? user, Map<String, dynamic> poById) {
    if (workOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No work orders found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedStatus == 'all' 
                  ? 'Create your first work order'
                  : 'No $_selectedStatus work orders',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(workOrdersProvider(_selectedStatus));
      },
      child: ListView.builder(
        itemCount: workOrders.length,
        itemBuilder: (context, index) {
          final workOrder = workOrders[index];
          return _buildWorkOrderCard(workOrder, user, poById);
        },
      ),
    );
  }

  Widget _buildWorkOrderCard(WorkOrder workOrder, User? user, Map<String, dynamic> poById) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkOrderDetailScreen(workOrder: workOrder),
            ),
          ).then((_) {
            // Refresh list when returning from detail screen
            ref.invalidate(workOrdersProvider(_selectedStatus));
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workOrder.woId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: workOrder.isOpen ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      workOrder.statusDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.business, 'Vendor', workOrder.vendorName ?? 'Unknown'),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.directions_car, 'Vehicle', workOrder.displayVehicle),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.category, 'Category', workOrder.categoryDisplay),
              if ((workOrder.linkedPoIds ?? []).isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final poId in workOrder.linkedPoIds!)
                      _buildPoChip(poId, poById[poId]?.vendorName as String?, poById[poId]?.status as String?)
                  ],
                ),
              ],
              if (workOrder.billNo != null) ...[
                const SizedBox(height: 4),
                _buildInfoRow(Icons.receipt, 'Bill No.', workOrder.billNo!),
              ],
              if (workOrder.remarkText?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  workOrder.remarkText!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Created: ${workOrder.createdAt ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (user?.canManageWorkOrders == true)
                    PopupMenuButton<String>(
                      onSelected: (String action) {
                        _handleWorkOrderAction(action, workOrder);
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        if (workOrder.isOpen)
                          const PopupMenuItem(
                            value: 'close',
                            child: Text('Close'),
                          ),
                        if (user?.canEnterBillNumbers == true)
                          const PopupMenuItem(
                            value: 'bill',
                            child: Text('Update Bill No.'),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPoChip(String poId, String? vendorName, String? status) {
    final color = (status ?? 'open') == 'open' ? Colors.blue[50] : Colors.grey[200];
    final border = (status ?? 'open') == 'open' ? Colors.blue[200] : Colors.grey[300];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long, size: 14),
          const SizedBox(width: 4),
          Text(poId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          if (vendorName != null) ...[
            const SizedBox(width: 6),
            Text('•', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(width: 6),
            Text(vendorName, style: const TextStyle(fontSize: 12)),
          ]
        ],
      ),
    );
  }

  void _showWorkOrderDetails(WorkOrder workOrder, User? user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workOrder.woId),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Vendor', workOrder.vendorName ?? 'Unknown'),
              _buildDetailRow('Vehicle', workOrder.displayVehicle),
              _buildDetailRow('Category', workOrder.categoryDisplay),
              _buildDetailRow('Status', workOrder.statusDisplay),
              if (workOrder.billNo != null)
                _buildDetailRow('Bill No.', workOrder.billNo!),
              if (workOrder.linkedPoId != null)
                _buildDetailRow('Linked PO', workOrder.linkedPoId!),
              if (workOrder.remarkText?.isNotEmpty == true)
                _buildDetailRow('Remarks', workOrder.remarkText!),
              _buildDetailRow('Created By', workOrder.createdByName ?? 'Unknown'),
              _buildDetailRow('Created At', workOrder.createdAt ?? 'Unknown'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _handleWorkOrderAction(String action, WorkOrder workOrder) {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit screen
        break;
      case 'close':
        _closeWorkOrder(workOrder);
        break;
      case 'bill':
        _updateBillNumber(workOrder);
        break;
    }
  }

  void _closeWorkOrder(WorkOrder workOrder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Work Order'),
        content: Text('Are you sure you want to close work order ${workOrder.woId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final service = ref.read(workOrderServiceProvider);
                await service.closeWorkOrder(workOrder.id!);
                ref.invalidate(workOrdersProvider(_selectedStatus));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Work order closed successfully')),
                );
              } catch (e) {
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

  void _updateBillNumber(WorkOrder workOrder) {
    final controller = TextEditingController(text: workOrder.billNo);
    
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
              try {
                final service = ref.read(workOrderServiceProvider);
                await service.updateBillNumber(workOrder.id!, billNo);
                ref.invalidate(workOrdersProvider(_selectedStatus));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bill number updated successfully')),
                );
              } catch (e) {
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