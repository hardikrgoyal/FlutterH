import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../services/list_management_service.dart';
import '../../auth/auth_service.dart';

class ListItemDetailScreen extends ConsumerStatefulWidget {
  final String listTypeCode;
  final int? itemId; // null for creating new item
  
  const ListItemDetailScreen({
    super.key,
    required this.listTypeCode,
    this.itemId,
  });

  @override
  ConsumerState<ListItemDetailScreen> createState() => _ListItemDetailScreenState();
}

class _ListItemDetailScreenState extends ConsumerState<ListItemDetailScreen>
    with SingleTickerProviderStateMixin {
  
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sortOrderController = TextEditingController();
  
  bool _isActive = true;
  bool _isEditing = false;
  bool _isSaving = false;
  SimpleListItem? _originalItem;
  AllListsData? _listData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isEditing = widget.itemId == null; // New item starts in edit mode
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItemData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _loadItemData() async {
    // Load all lists to get the list data
    await ref.read(listManagementProvider.notifier).loadAllLists();
    final allLists = ref.read(listManagementProvider).allLists;
    _listData = allLists.where((list) => list.code == widget.listTypeCode).firstOrNull;
    
    if (widget.itemId != null && _listData != null) {
      // Find the specific item
      _originalItem = _listData!.items.where((item) => item.id == widget.itemId).firstOrNull;
      
      if (_originalItem != null) {
        _populateForm(_originalItem!);
        // Load audit logs for this item
        await ref.read(listManagementProvider.notifier).loadAuditLogsForItem(widget.listTypeCode, widget.itemId!);
      }
    } else if (_listData != null) {
      // Set default sort order for new items
      _sortOrderController.text = '${_listData!.items.length + 1}';
    }
    
    setState(() {});
  }

  void _populateForm(SimpleListItem item) {
    _nameController.text = item.name;
    _codeController.text = item.code ?? '';
    _sortOrderController.text = item.sortOrder.toString();
    _isActive = true; // SimpleListItem doesn't have isActive, assume true
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listManagementProvider);
    final authState = ref.watch(authStateProvider);
    final canEdit = authState.user?.isAdmin == true || authState.user?.isManager == true;
    
    final isNewItem = widget.itemId == null;
    final listTypeDisplay = _listData?.name ?? widget.listTypeCode;

    if (_listData == null) {
      return Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const LoadingWidget(message: 'Loading item details...'),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(isNewItem 
            ? 'New $listTypeDisplay Item'
            : _originalItem?.name ?? 'Item Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!isNewItem && canEdit && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveItem,
            ),
          if (_isEditing && !isNewItem)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() => _isEditing = false);
                if (_originalItem != null) {
                  _populateForm(_originalItem!);
                }
              },
            ),
        ],
        bottom: !isNewItem ? TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Details', icon: Icon(Icons.info_outline)),
            Tab(text: 'Audit Trail', icon: Icon(Icons.history)),
          ],
        ) : null,
      ),
      body: isNewItem ? _buildDetailsTab() : TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildAuditTrailTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List Type Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _getIconForListType(widget.listTypeCode),
                      size: 32,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _listData!.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_listData!.description != null)
                            Text(
                              _listData!.description!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Basic Information Section
            _buildSectionHeader('Basic Information'),
            const SizedBox(height: 16),
            
            // Item Name
            TextFormField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Item name is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Item Code
            TextFormField(
              controller: _codeController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: 'Item Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
                helperText: 'Optional system code for this item',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              enabled: _isEditing,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
                helperText: 'Optional description for this item',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sort Order
            TextFormField(
              controller: _sortOrderController,
              enabled: _isEditing,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sort Order *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sort),
                helperText: 'Controls the display order in dropdowns',
              ),
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
            
            const SizedBox(height: 24),
            
            // Status Section
            _buildSectionHeader('Status'),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Active Status'),
              subtitle: Text(_isActive ? 'Item is active and available for use' : 'Item is inactive'),
              value: _isActive,
              onChanged: _isEditing ? (value) => setState(() => _isActive = value) : null,
              activeColor: AppColors.primary,
            ),
            
            const SizedBox(height: 24),
            
            // Metadata Section (only for existing items)
            if (_originalItem != null) ...[
              _buildSectionHeader('Information'),
              const SizedBox(height: 16),
              _buildInfoCard(),
            ],
            
            const SizedBox(height: 32),
            
            // Action Buttons
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving 
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(widget.itemId == null ? 'Create Item' : 'Update Item'),
                    ),
                  ),
                  if (widget.itemId != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () {
                          setState(() => _isEditing = false);
                          if (_originalItem != null) {
                            _populateForm(_originalItem!);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTrailTab() {
    final auditLogs = ref.watch(listManagementProvider)
        .getAuditLogsForItem(widget.listTypeCode, widget.itemId!);
    
    if (auditLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No audit trail available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Changes to this item will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: auditLogs.length,
      itemBuilder: (context, index) {
        final log = auditLogs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getActionColor(log.action),
              child: Icon(
                _getActionIcon(log.action),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              log.actionDisplay,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('By: ${log.performedByName ?? 'System'}'),
                Text(DateFormat('MMM dd, yyyy HH:mm').format(log.createdAt)),
                if (log.changes != null && log.changes!.isNotEmpty)
                  Text(
                    _formatChanges(log.changes!),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'created':
        return Colors.green;
      case 'updated':
        return Colors.blue;
      case 'deleted':
        return Colors.red;
      case 'activated':
        return Colors.green;
      case 'deactivated':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'created':
        return Icons.add;
      case 'updated':
        return Icons.edit;
      case 'deleted':
        return Icons.delete;
      case 'activated':
        return Icons.check;
      case 'deactivated':
        return Icons.pause;
      default:
        return Icons.info;
    }
  }

  String _formatChanges(Map<String, dynamic> changes) {
    if (changes['fields'] != null) {
      final fields = changes['fields'] as Map<String, dynamic>;
      if (fields.isEmpty) return 'No changes recorded';
      
      final changesList = <String>[];
      fields.forEach((fieldName, fieldChanges) {
        if (fieldChanges is Map) {
          final oldValue = fieldChanges['old']?.toString() ?? 'null';
          final newValue = fieldChanges['new']?.toString() ?? 'null';
          final displayName = _getFieldDisplayName(fieldName);
          
          if (fieldName == 'is_active') {
            // Special formatting for boolean fields
            final oldDisplay = oldValue == 'true' ? 'Active' : 'Inactive';
            final newDisplay = newValue == 'true' ? 'Active' : 'Inactive';
            changesList.add('$displayName: $oldDisplay → $newDisplay');
          } else if (oldValue.isEmpty && newValue.isNotEmpty) {
            changesList.add('$displayName: Added "$newValue"');
          } else if (oldValue.isNotEmpty && newValue.isEmpty) {
            changesList.add('$displayName: Removed "$oldValue"');
          } else {
            changesList.add('$displayName: "$oldValue" → "$newValue"');
          }
        }
      });
      
      return changesList.join('\n');
    }
    return 'Changes recorded';
  }

  String _getFieldDisplayName(String fieldName) {
    switch (fieldName) {
      case 'name':
        return 'Name';
      case 'code':
        return 'Code';
      case 'description':
        return 'Description';
      case 'sort_order':
        return 'Sort Order';
      case 'is_active':
        return 'Status';
      default:
        return fieldName.replaceAll('_', ' ').split(' ')
            .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
            .join(' ');
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('Item ID', _originalItem!.id.toString()),
            const Divider(),
            _buildInfoRow('Sort Order', _originalItem!.sortOrder.toString()),
            if (_originalItem!.code != null) ...[
              const Divider(),
              _buildInfoRow('System Code', _originalItem!.code!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  IconData _getIconForListType(String code) {
    switch (code) {
      case 'cargo_types':
        return MdiIcons.packageVariant;
      case 'party_names':
        return Icons.business;
      case 'gate_locations':
        return MdiIcons.gate;
      case 'voucher_categories':
        return MdiIcons.receipt;
      case 'contract_types':
        return MdiIcons.fileDocument;
      case 'cost_types':
        return MdiIcons.cashMultiple;
      case 'in_out_options':
        return MdiIcons.swapHorizontal;
      case 'maintenance_categories':
        return MdiIcons.wrench;

      case 'document_types':
        return MdiIcons.fileDocumentOutline;
      case 'priority_levels':
        return MdiIcons.alertCircle;
      case 'status_options':
        return MdiIcons.checkboxMarkedCircle;
      default:
        return Icons.list;
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final listItem = ListItem(
        id: _originalItem?.id ?? 0,
        listType: _listData!.id,
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        sortOrder: int.parse(_sortOrderController.text),
        isActive: _isActive,
        createdBy: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (widget.itemId == null) {
        // Create new item
        success = await ref.read(listManagementProvider.notifier).addListItem(listItem);
      } else {
        // Update existing item
        success = await ref.read(listManagementProvider.notifier).updateListItem(widget.itemId!, listItem);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.itemId == null 
                ? 'Item created successfully' 
                : 'Item updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        if (widget.itemId == null) {
          // Navigate back to master data screen after creating
          context.go('/maintenance/master-data');
        } else {
          // Reload data and audit logs, then exit edit mode
          await _loadItemData();
          if (widget.itemId != null) {
            await ref.read(listManagementProvider.notifier).loadAuditLogsForItem(widget.listTypeCode, widget.itemId!);
          }
          setState(() => _isEditing = false);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.itemId == null 
                ? 'Failed to create item' 
                : 'Failed to update item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
} 