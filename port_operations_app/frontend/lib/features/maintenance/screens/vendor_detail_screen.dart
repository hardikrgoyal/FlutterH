import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../services/unified_vendor_service.dart';
import '../../auth/auth_service.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  final String vendorType; // 'po' or 'wo'
  final int? vendorId; // null for creating new vendor
  
  const VendorDetailScreen({
    super.key,
    required this.vendorType,
    this.vendorId,
  });

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen>
    with SingleTickerProviderStateMixin {
  
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isActive = true;
  bool _isEditing = false;
  bool _isSaving = false;
  UnifiedVendor? _originalVendor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isEditing = widget.vendorId == null; // New vendor starts in edit mode
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVendorData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadVendorData() async {
    if (widget.vendorId != null) {
      // Load existing vendor data
      await ref.read(unifiedVendorProvider.notifier).loadVendors(widget.vendorType);
      final vendors = ref.read(unifiedVendorProvider).getVendorsForType(widget.vendorType);
      _originalVendor = vendors.where((v) => v.id == widget.vendorId).firstOrNull;
      
      if (_originalVendor != null) {
        _populateForm(_originalVendor!);
        // Load audit logs
        await ref.read(unifiedVendorProvider.notifier).loadAuditLogs(widget.vendorType, widget.vendorId!);
      }
    }
  }

  void _populateForm(UnifiedVendor vendor) {
    _nameController.text = vendor.name;
    _contactPersonController.text = vendor.contactPerson ?? '';
    _phoneController.text = vendor.phoneNumber ?? '';
    _emailController.text = vendor.email ?? '';
    _addressController.text = vendor.address ?? '';
    _isActive = vendor.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(unifiedVendorProvider);
    final authState = ref.watch(authStateProvider);
    final canEdit = authState.user?.isAdmin == true || authState.user?.isManager == true;
    
    final isNewVendor = widget.vendorId == null;
    final vendorTypeDisplay = widget.vendorType == 'po' ? 'Purchase Order' : 'Work Order';

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(isNewVendor 
            ? 'New $vendorTypeDisplay Vendor'
            : _originalVendor?.name ?? 'Vendor Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!isNewVendor && canEdit && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveVendor,
            ),
          if (_isEditing && !isNewVendor)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() => _isEditing = false);
                if (_originalVendor != null) {
                  _populateForm(_originalVendor!);
                }
              },
            ),
        ],
        bottom: !isNewVendor ? TabBar(
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
      body: isNewVendor ? _buildDetailsTab() : TabBarView(
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
            // Vendor Type Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      widget.vendorType == 'po' ? MdiIcons.cartOutline : MdiIcons.wrenchOutline,
                      size: 32,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.vendorType == 'po' ? 'Purchase Order' : 'Work Order'} Vendor',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.vendorType == 'po' 
                                ? 'Used for purchase orders and procurement'
                                : 'Used for work orders and maintenance',
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
            
            // Vendor Name
            TextFormField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: 'Vendor Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vendor name is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Contact Person
            TextFormField(
              controller: _contactPersonController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                labelText: 'Contact Person',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Phone Number
            TextFormField(
              controller: _phoneController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Email
            TextFormField(
              controller: _emailController,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && !value.contains('@')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Address
            TextFormField(
              controller: _addressController,
              enabled: _isEditing,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                alignLabelWithHint: true,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Status Section
            _buildSectionHeader('Status'),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Active Status'),
              subtitle: Text(_isActive ? 'Vendor is active' : 'Vendor is inactive'),
              value: _isActive,
              onChanged: _isEditing ? (value) => setState(() => _isActive = value) : null,
              activeColor: AppColors.primary,
            ),
            
            const SizedBox(height: 24),
            
            // Metadata Section (only for existing vendors)
            if (_originalVendor != null) ...[
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
                      onPressed: _isSaving ? null : _saveVendor,
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
                          : Text(widget.vendorId == null ? 'Create Vendor' : 'Update Vendor'),
                    ),
                  ),
                  if (widget.vendorId != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () {
                          setState(() => _isEditing = false);
                          if (_originalVendor != null) {
                            _populateForm(_originalVendor!);
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
    final auditLogs = ref.watch(unifiedVendorProvider)
        .getAuditLogsForVendor('${widget.vendorType}_${widget.vendorId}');
    
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
                Text('By: ${log.performedByName ?? 'Unknown User'}'),
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
            _buildInfoRow('Created By', _originalVendor?.createdByName ?? 'Unknown'),
            const Divider(),
            _buildInfoRow('Created At', 
                DateFormat('MMM dd, yyyy HH:mm').format(_originalVendor!.createdAt)),
            const Divider(),
            _buildInfoRow('Vendor ID', _originalVendor!.id.toString()),
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

  Future<void> _saveVendor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final vendor = UnifiedVendor(
        id: _originalVendor?.id ?? 0,
        name: _nameController.text.trim(),
        contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        isActive: _isActive,
        createdBy: _originalVendor?.createdBy ?? 0,
        createdAt: _originalVendor?.createdAt ?? DateTime.now(),
        vendorType: widget.vendorType,
      );

      bool success;
      if (widget.vendorId == null) {
        // Create new vendor
        success = await ref.read(unifiedVendorProvider.notifier).createVendor(widget.vendorType, vendor);
      } else {
        // Update existing vendor
        success = await ref.read(unifiedVendorProvider.notifier).updateVendor(widget.vendorType, widget.vendorId!, vendor);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vendorId == null 
                ? 'Vendor created successfully' 
                : 'Vendor updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        if (widget.vendorId == null) {
          // Navigate back to master data screen after creating
          context.go('/maintenance/master-data');
        } else {
          // Reload data and exit edit mode
          await _loadVendorData();
          setState(() => _isEditing = false);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vendorId == null 
                ? 'Failed to create vendor' 
                : 'Failed to update vendor'),
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
      case 'contact_person':
        return 'Contact Person';
      case 'phone_number':
        return 'Phone Number';
      case 'email':
        return 'Email';
      case 'address':
        return 'Address';
      case 'is_active':
        return 'Status';
      default:
        return fieldName.replaceAll('_', ' ').split(' ')
            .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
            .join(' ');
    }
  }
} 