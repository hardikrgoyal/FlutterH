import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/models/purchase_order_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../services/purchase_order_service.dart';
import '../../auth/auth_service.dart';
import 'create_purchase_order_screen.dart';
import 'purchase_order_detail_screen.dart';

class PurchaseOrdersScreen extends ConsumerStatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  ConsumerState<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends ConsumerState<PurchaseOrdersScreen> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Purchase Orders'),
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
      floatingActionButton: user?.canCreatePurchaseOrders == true
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePurchaseOrderScreen(),
                  ),
                ).then((result) {
                  if (result == true) {
                    // Refresh the list after creating
                    ref.invalidate(purchaseOrdersProvider(_selectedStatus));
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
    final purchaseOrdersAsync = ref.watch(purchaseOrdersProvider(_selectedStatus));

    return purchaseOrdersAsync.when(
      data: (purchaseOrders) => _buildPurchaseOrdersList(purchaseOrders, user),
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
              onPressed: () => ref.invalidate(purchaseOrdersProvider(_selectedStatus)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseOrdersList(List<PurchaseOrder> purchaseOrders, User? user) {
    if (purchaseOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No purchase orders found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedStatus == 'all' 
                  ? 'Create your first purchase order'
                  : 'No $_selectedStatus purchase orders',
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
        ref.invalidate(purchaseOrdersProvider(_selectedStatus));
      },
      child: ListView.builder(
        itemCount: purchaseOrders.length,
        itemBuilder: (context, index) {
          final purchaseOrder = purchaseOrders[index];
          return _buildPurchaseOrderCard(purchaseOrder, user);
        },
      ),
    );
  }

  Widget _buildPurchaseOrderCard(PurchaseOrder purchaseOrder, User? user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PurchaseOrderDetailScreen(purchaseOrder: purchaseOrder),
            ),
          ).then((_) {
            // Refresh list when returning from detail screen
            ref.invalidate(purchaseOrdersProvider(_selectedStatus));
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
                      purchaseOrder.poId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: purchaseOrder.isOpen ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      purchaseOrder.statusDisplay,
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
              _buildInfoRow(Icons.business, 'Vendor', purchaseOrder.vendorName ?? 'Unknown'),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.directions_car, 'Target', purchaseOrder.displayTarget),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.category, 'Category', purchaseOrder.categoryDisplay),
              if (purchaseOrder.billNo != null) ...[
                const SizedBox(height: 4),
                _buildInfoRow(Icons.receipt, 'Bill No.', purchaseOrder.billNo!),
              ],
              if ((purchaseOrder.itemsCount ?? 0) > 0) ...[
                const SizedBox(height: 4),
                _buildInfoRow(Icons.list, 'Items', '${purchaseOrder.itemsCount ?? 0} items'),
              ],
              if ((purchaseOrder.totalAmount ?? 0) > 0) ...[
                const SizedBox(height: 4),
                _buildInfoRow(Icons.currency_rupee, 'Total', '₹${(purchaseOrder.totalAmount ?? 0).toStringAsFixed(2)}'),
              ],
              if (purchaseOrder.hasDuplicateWarning) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Duplicate warning: Similar PO exists',
                          style: TextStyle(color: Colors.orange[800], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (purchaseOrder.remarkText?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  purchaseOrder.remarkText!,
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
                      'Created: ${purchaseOrder.createdAt ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (user?.canManagePurchaseOrders == true)
                    PopupMenuButton<String>(
                      onSelected: (String action) {
                        _handlePurchaseOrderAction(action, purchaseOrder);
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        if (purchaseOrder.isOpen)
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

  void _showPurchaseOrderDetails(PurchaseOrder purchaseOrder, User? user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(purchaseOrder.poId),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Vendor', purchaseOrder.vendorName ?? 'Unknown'),
              _buildDetailRow('Target', purchaseOrder.displayTarget),
              _buildDetailRow('Category', purchaseOrder.categoryDisplay),
              _buildDetailRow('Status', purchaseOrder.statusDisplay),
              if (purchaseOrder.billNo != null)
                _buildDetailRow('Bill No.', purchaseOrder.billNo!),
              if (purchaseOrder.linkedWoId != null)
                _buildDetailRow('Linked WO', purchaseOrder.linkedWoId!),
              if ((purchaseOrder.itemsCount ?? 0) > 0)
                _buildDetailRow('Items Count', '${purchaseOrder.itemsCount ?? 0}'),
              if ((purchaseOrder.totalAmount ?? 0) > 0)
                _buildDetailRow('Total Amount', '₹${(purchaseOrder.totalAmount ?? 0).toStringAsFixed(2)}'),
              if (purchaseOrder.remarkText?.isNotEmpty == true)
                _buildDetailRow('Remarks', purchaseOrder.remarkText!),
              _buildDetailRow('Created By', purchaseOrder.createdByName ?? 'Unknown'),
              _buildDetailRow('Created At', purchaseOrder.createdAt ?? 'Unknown'),
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
            width: 100,
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

  void _handlePurchaseOrderAction(String action, PurchaseOrder purchaseOrder) {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit Purchase Order - Coming Soon!')),
        );
        break;
      case 'close':
        _closePurchaseOrder(purchaseOrder);
        break;
      case 'bill':
        _updateBillNumber(purchaseOrder);
        break;
    }
  }

  void _closePurchaseOrder(PurchaseOrder purchaseOrder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Purchase Order'),
        content: Text('Are you sure you want to close purchase order ${purchaseOrder.poId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final service = ref.read(purchaseOrderServiceProvider);
                await service.closePurchaseOrder(purchaseOrder.id!);
                ref.invalidate(purchaseOrdersProvider(_selectedStatus));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchase order closed successfully')),
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

  void _updateBillNumber(PurchaseOrder purchaseOrder) {
    final controller = TextEditingController(text: purchaseOrder.billNo);
    
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
                final service = ref.read(purchaseOrderServiceProvider);
                await service.updateBillNumber(purchaseOrder.id!, billNo);
                ref.invalidate(purchaseOrdersProvider(_selectedStatus));
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