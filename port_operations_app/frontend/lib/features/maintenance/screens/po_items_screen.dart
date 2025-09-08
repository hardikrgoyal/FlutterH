import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/models/purchase_order_model.dart';
import '../../../shared/models/user_model.dart';
import '../services/po_item_service.dart';
import '../../auth/auth_service.dart';

class POItemsScreen extends ConsumerStatefulWidget {
  final PurchaseOrder purchaseOrder;

  const POItemsScreen({
    super.key,
    required this.purchaseOrder,
  });

  @override
  ConsumerState<POItemsScreen> createState() => _POItemsScreenState();
}

class _POItemsScreenState extends ConsumerState<POItemsScreen> {
  List<POItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final service = ref.read(poItemServiceProvider);
      final items = await service.getPOItems(widget.purchaseOrder.id!);

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Items - ${widget.purchaseOrder.poId}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (user?.canItemizePurchaseOrders == true)
            IconButton(
              onPressed: _showAddItemDialog,
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _buildBody(user),
    );
  }

  Widget _buildBody(User? user) {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadItems,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No items added yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to complete the purchase order',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            if (user?.canItemizePurchaseOrders == true)
              ElevatedButton.icon(
                onPressed: _showAddItemDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Items: ${_items.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Amount: ₹${_calculateTotalAmount().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (user?.canItemizePurchaseOrders == true)
                ElevatedButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        // Items List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadItems,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildItemCard(item, user);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(POItem item, User? user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (user?.canItemizePurchaseOrders == true)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditItemDialog(item);
                      } else if (value == 'delete') {
                        _deleteItem(item);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Qty: ${item.quantity}'),
                ),
                Expanded(
                  child: Text('Rate: ₹${item.rate.toStringAsFixed(2)}'),
                ),
                Expanded(
                  child: Text(
                    'Amount: ₹${item.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalAmount() {
    return _items.fold(0.0, (sum, item) => sum + item.amount);
  }

  void _showAddItemDialog() {
    _showItemDialog();
  }

  void _showEditItemDialog(POItem item) {
    _showItemDialog(item: item);
  }

  void _showItemDialog({POItem? item}) {
    final itemNameController = TextEditingController(text: item?.itemName ?? '');
    final quantityController = TextEditingController(text: item?.quantity.toString() ?? '');
    final rateController = TextEditingController(text: item?.rate.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add Item' : 'Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: rateController,
                      decoration: const InputDecoration(
                        labelText: 'Rate (₹) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
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
            onPressed: () {
              _saveItem(
                item: item,
                itemName: itemNameController.text.trim(),
                quantity: double.tryParse(quantityController.text.trim()) ?? 0,
                rate: double.tryParse(rateController.text.trim()) ?? 0,
              );
              Navigator.pop(context);
            },
            child: Text(item == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _saveItem({
    POItem? item,
    required String itemName,
    required double quantity,
    required double rate,
  }) async {
    if (itemName.isEmpty || quantity <= 0 || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields with valid values')),
      );
      return;
    }

    try {
      final service = ref.read(poItemServiceProvider);

      if (item == null) {
        // Create new item
        final newItem = POItem(
          purchaseOrder: widget.purchaseOrder.id!,
          itemName: itemName,
          quantity: quantity,
          rate: rate,
          amount: quantity * rate,
        );
        await service.createPOItem(newItem);
      } else {
        // Update existing item
        final updatedItem = POItem(
          id: item.id,
          purchaseOrder: widget.purchaseOrder.id!,
          itemName: itemName,
          quantity: quantity,
          rate: rate,
          amount: quantity * rate,
        );
        await service.updatePOItem(item.id!, updatedItem);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(item == null ? 'Item added successfully' : 'Item updated successfully')),
      );

      _loadItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving item: $e')),
      );
    }
  }

  void _deleteItem(POItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.itemName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(poItemServiceProvider);
        await service.deletePOItem(item.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );

        _loadItems();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }
} 