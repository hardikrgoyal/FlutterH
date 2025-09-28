import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../services/list_management_service.dart';
import '../../auth/auth_service.dart';

class ListsManagementScreen extends ConsumerStatefulWidget {
  const ListsManagementScreen({super.key});

  @override
  ConsumerState<ListsManagementScreen> createState() => _ListsManagementScreenState();
}

class _ListsManagementScreenState extends ConsumerState<ListsManagementScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(listManagementProvider.notifier).loadAllLists();
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
    final authState = ref.watch(authStateProvider);

    if (state.isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading lists...'),
      );
    }

    if (state.error != null) {
      return Scaffold(
        body: AppErrorWidget(
          message: state.error!,
          onRetry: () => ref.read(listManagementProvider.notifier).loadAllLists(),
        ),
      );
    }

    if (state.allLists.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lists Management'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'No lists found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Initialize tab controller with the number of lists
    if (_tabController == null || _tabController!.length != state.allLists.length) {
      _tabController?.dispose();
      _tabController = TabController(
        length: state.allLists.length,
        vsync: this,
      );
    }

    final canEdit = authState.user?.isAdmin == true || authState.user?.isManager == true;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Lists Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: state.allLists.map((listData) {
            return Tab(
              text: '${listData.name} (${listData.itemsCount})',
              icon: _getIconForListType(listData.code),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: state.allLists.map((listData) {
          return ListItemsTab(
            listData: listData,
            canEdit: canEdit,
          );
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

class ListItemsTab extends ConsumerWidget {
  final AllListsData listData;
  final bool canEdit;

  const ListItemsTab({
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
                  onPressed: () => _showAddItemDialog(context, ref),
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
                        trailing: canEdit
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditItemDialog(context, ref, item);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmation(context, ref, item);
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
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
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