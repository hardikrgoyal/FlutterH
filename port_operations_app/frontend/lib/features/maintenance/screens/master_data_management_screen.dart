import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../services/list_management_service.dart';
import '../services/unified_vendor_service.dart';
import '../../auth/auth_service.dart';

class MasterDataManagementScreen extends ConsumerStatefulWidget {
  const MasterDataManagementScreen({super.key});

  @override
  ConsumerState<MasterDataManagementScreen> createState() => _MasterDataManagementScreenState();
}

class _MasterDataManagementScreenState extends ConsumerState<MasterDataManagementScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(listManagementProvider.notifier).loadAllLists();
      ref.read(unifiedVendorProvider.notifier).loadAllVendors();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listManagementProvider);
    final vendorState = ref.watch(unifiedVendorProvider);
    final authState = ref.watch(authStateProvider);

    if (state.isLoading) {
      return const Scaffold(
        drawer: AppDrawer(),
        body: LoadingWidget(message: 'Loading master data...'),
      );
    }

    if (state.error != null) {
      return Scaffold(
        drawer: const AppDrawer(),
        body: AppErrorWidget(
          message: state.error!,
          onRetry: () => ref.read(listManagementProvider.notifier).loadAllLists(),
        ),
      );
    }

    // Create tabs for vendors + lists
    final allTabs = [
      _TabData(
        name: 'PO Vendors',
        code: 'po_vendors',
        description: 'Purchase Order Vendors',
        icon: Icon(MdiIcons.cartOutline, size: 20),
        isVendor: true,
      ),
      _TabData(
        name: 'WO Vendors',
        code: 'wo_vendors', 
        description: 'Work Order Vendors',
        icon: Icon(MdiIcons.wrenchOutline, size: 20),
        isVendor: true,
      ),
      ...state.allLists.map((listData) => _TabData(
        name: '${listData.name} (${listData.itemsCount})',
        code: listData.code,
        description: listData.description,
        icon: _getIconForListType(listData.code),
        isVendor: false,
        listData: listData,
      )).toList(),
    ];

    // Initialize tab controller
    if (_tabController == null || _tabController!.length != allTabs.length) {
      _tabController?.dispose();
      _tabController = TabController(
        length: allTabs.length,
        vsync: this,
      );
    }

    final canEdit = authState.user?.isAdmin == true || authState.user?.isManager == true;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Master Data Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: allTabs.map((tabData) {
            return Tab(
              text: tabData.name,
              icon: tabData.icon,
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: allTabs.map((tabData) {
          if (tabData.isVendor) {
            return VendorManagementTab(
              vendorType: tabData.code,
              canEdit: canEdit,
            );
          } else {
            return MasterDataItemsTab(
              listData: tabData.listData!,
              canEdit: canEdit,
            );
          }
        }).toList(),
      ),
    );
  }

  Widget _getIconForListType(String code) {
    switch (code) {
      case 'cargo_types':
        return Icon(MdiIcons.packageVariant, size: 20);
      case 'party_names':
        return const Icon(Icons.business, size: 20);
      case 'gate_locations':
        return Icon(MdiIcons.gate, size: 20);
      case 'voucher_categories':
        return Icon(MdiIcons.receipt, size: 20);
      case 'contract_types':
        return Icon(MdiIcons.fileDocument, size: 20);
      case 'cost_types':
        return Icon(MdiIcons.cashMultiple, size: 20);
      case 'in_out_options':
        return Icon(MdiIcons.swapHorizontal, size: 20);
      case 'maintenance_categories':
        return Icon(MdiIcons.wrench, size: 20);
      case 'vehicle_types_list':
        return Icon(MdiIcons.carMultiple, size: 20);
      case 'document_types':
        return Icon(MdiIcons.fileDocumentOutline, size: 20);
      case 'priority_levels':
        return Icon(MdiIcons.alertCircle, size: 20);
      case 'status_options':
        return Icon(MdiIcons.checkboxMarkedCircle, size: 20);
      default:
        return const Icon(Icons.list, size: 20);
    }
  }
}

class _TabData {
  final String name;
  final String code;
  final String? description;
  final Widget icon;
  final bool isVendor;
  final AllListsData? listData;

  _TabData({
    required this.name,
    required this.code,
    this.description,
    required this.icon,
    required this.isVendor,
    this.listData,
  });
}

class VendorManagementTab extends ConsumerWidget {
  final String vendorType;
  final bool canEdit;

  const VendorManagementTab({
    super.key,
    required this.vendorType,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorState = ref.watch(unifiedVendorProvider);
    final type = vendorType == 'po_vendors' ? 'po' : 'wo';
    final vendors = vendorState.getVendorsForType(type);
    
    return Column(
      children: [
        // Header with description and add button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendorType == 'po_vendors' ? 'Purchase Order Vendors' : 'Work Order Vendors',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vendorType == 'po_vendors' 
                          ? 'Vendors for purchase orders and procurement (${vendors.length} vendors)'
                          : 'Vendors for work orders and maintenance (${vendors.length} vendors)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit) ...[
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _navigateToVendorDetail(context, type, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Vendor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Vendors list
        Expanded(
          child: vendorState.isLoading
              ? const LoadingWidget(message: 'Loading vendors...')
              : vendors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            vendorType == 'po_vendors' ? Icons.shopping_cart_outlined : Icons.build_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No vendors found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          if (canEdit) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _navigateToVendorDetail(context, type, null),
                              child: const Text('Add your first vendor'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vendors.length,
                      itemBuilder: (context, index) {
                        final vendor = vendors[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: vendor.isActive ? AppColors.primary : Colors.grey,
                              foregroundColor: Colors.white,
                              child: Text(vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V'),
                            ),
                            title: Text(
                              vendor.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (vendor.contactPerson != null)
                                  Text('Contact: ${vendor.contactPerson}'),
                                if (vendor.phoneNumber != null)
                                  Text('Phone: ${vendor.phoneNumber}'),
                                Text(
                                  vendor.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: vendor.isActive ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () => _navigateToVendorDetail(context, type, vendor.id),
                            trailing: canEdit
                                ? PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _navigateToVendorDetail(context, type, vendor.id);
                                      } else if (value == 'delete') {
                                        _showDeleteConfirmation(context, ref, type, vendor);
                                      } else if (value == 'toggle_status') {
                                        _toggleVendorStatus(context, ref, type, vendor);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'toggle_status',
                                        child: Row(
                                          children: [
                                            Icon(
                                              vendor.isActive ? Icons.pause : Icons.play_arrow,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(vendor.isActive ? 'Deactivate' : 'Activate'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _navigateToVendorDetail(BuildContext context, String type, int? vendorId) {
    // Navigate to full-page vendor detail screen
    context.push('/maintenance/vendor-detail/$type${vendorId != null ? '/$vendorId' : '/new'}');
  }

  void _toggleVendorStatus(BuildContext context, WidgetRef ref, String type, UnifiedVendor vendor) async {
    final updatedVendor = vendor.copyWith(isActive: !vendor.isActive);
    final success = await ref.read(unifiedVendorProvider.notifier).updateVendor(type, vendor.id, updatedVendor);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Vendor ${vendor.isActive ? 'deactivated' : 'activated'} successfully'
              : 'Failed to update vendor status'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String type, UnifiedVendor vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vendor'),
        content: Text('Are you sure you want to delete "${vendor.name}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref.read(unifiedVendorProvider.notifier).deleteVendor(type, vendor.id);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Vendor deleted successfully' : 'Failed to delete vendor'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class MasterDataItemsTab extends ConsumerWidget {
  final AllListsData listData;
  final bool canEdit;

  const MasterDataItemsTab({
    super.key,
    required this.listData,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Header with description and add button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listData.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (listData.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        listData.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canEdit) ...[
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/maintenance/list-item-detail/${listData.code}/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Items list
        Expanded(
          child: listData.items.isEmpty
              ? const Center(
                  child: Text(
                    'No items found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listData.items.length,
                  itemBuilder: (context, index) {
                    final item = listData.items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          child: Text('${item.sortOrder}'),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: item.code != null
                            ? Text('Code: ${item.code}')
                            : null,
                        onTap: () => _navigateToItemDetail(context, item),
                        trailing: canEdit
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditItemDialog(context, ref, item);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmation(context, ref, item);
                                  } else if (value == 'audit') {
                                    _showItemAuditTrail(context, ref, item);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'audit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.history, size: 18),
                                        SizedBox(width: 8),
                                        Text('Audit Trail'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : IconButton(
                                icon: const Icon(Icons.history),
                                onPressed: () => _showItemAuditTrail(context, ref, item),
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _navigateToItemDetail(BuildContext context, SimpleListItem item) {
    // Navigate to full-page item detail screen
    context.push('/maintenance/list-item-detail/${listData.code}/${item.id}');
  }

  void _showItemAuditTrail(BuildContext context, WidgetRef ref, SimpleListItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audit Trail: ${item.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: Center(
                  child: Text(
                    'Audit trail functionality will be implemented here\nsimilar to vendor audit trails',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    _showItemDialog(
      context,
      ref,
      title: 'Add ${listData.name} Item',
      isEdit: false,
    );
  }

  void _showEditItemDialog(BuildContext context, WidgetRef ref, SimpleListItem item) {
    _showItemDialog(
      context,
      ref,
      title: 'Edit ${listData.name} Item',
      isEdit: true,
      existingItem: item,
    );
  }

  void _showItemDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required bool isEdit,
    SimpleListItem? existingItem,
  }) {
    final nameController = TextEditingController(text: existingItem?.name ?? '');
    final codeController = TextEditingController(text: existingItem?.code ?? '');
    final sortOrderController = TextEditingController(
      text: existingItem?.sortOrder.toString() ?? '${listData.items.length + 1}',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  border: OutlineInputBorder(),
                  hintText: 'Optional system code',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: sortOrderController,
                decoration: const InputDecoration(
                  labelText: 'Sort Order *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Sort order is required';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null || intValue < 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final listItem = ListItem(
                  id: existingItem?.id ?? 0,
                  listType: listData.id,
                  name: nameController.text.trim(),
                  code: codeController.text.trim().isEmpty ? null : codeController.text.trim(),
                  sortOrder: int.parse(sortOrderController.text),
                  isActive: true,
                  createdBy: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                bool success;
                if (isEdit && existingItem != null) {
                  success = await ref.read(listManagementProvider.notifier)
                      .updateListItem(existingItem.id, listItem);
                } else {
                  success = await ref.read(listManagementProvider.notifier)
                      .addListItem(listItem);
                }

                if (success && context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Item updated successfully' : 'Item added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Failed to update item' : 'Failed to add item'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, SimpleListItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await ref.read(listManagementProvider.notifier)
                  .deleteListItem(item.id);

              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Item deleted successfully' : 'Failed to delete item'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 