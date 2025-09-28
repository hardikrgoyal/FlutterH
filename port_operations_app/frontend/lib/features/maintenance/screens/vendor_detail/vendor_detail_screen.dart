import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/auth_service.dart';
import '../../services/po_vendor_service.dart';
import '../../services/wo_vendor_service.dart';
import '../../services/vendor_audit_service.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  final dynamic vendor; // Can be POVendor or WOVendor
  final String vendorType; // 'PO' or 'WO'

  const VendorDetailScreen({
    super.key,
    required this.vendor,
    required this.vendorType,
  });

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  
  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.vendor.name);
    _contactPersonController = TextEditingController(text: widget.vendor.contactPerson ?? '');
    _phoneController = TextEditingController(text: widget.vendor.phoneNumber ?? '');
    _emailController = TextEditingController(text: widget.vendor.email ?? '');
    _addressController = TextEditingController(text: widget.vendor.address ?? '');
    _isActive = widget.vendor.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if user is admin
    final isAdmin = user.role == 'admin';

    return Scaffold(
      
      appBar: AppBar(
        title: Text('${widget.vendorType} Vendor Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: isAdmin ? _buildAppBarActions() : null,
      ),      body: isAdmin 
          ? _buildAdminDetailView(context, widget.vendor, widget.vendorType) 
          : _buildUserDetailView(context, widget.vendor, widget.vendorType),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isEditing) {
      return [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancelEdit,
          tooltip: 'Cancel Edit',
        ),
        IconButton(
          icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save),
          onPressed: _isLoading ? null : _saveChanges,
          tooltip: 'Save Changes',
        ),
      ];
    } else {
      return [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _startEdit,
          tooltip: 'Edit Vendor',
        ),
      ];
    }
  }

  void _startEdit() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _initializeControllers(); // Reset to original values
    });
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vendor name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vendorData = {
        'name': _nameController.text.trim(),
        'contact_person': _contactPersonController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'is_active': _isActive,
      };

      if (widget.vendorType == 'PO') {
        await ref.read(poVendorServiceProvider).updatePOVendor(widget.vendor.id, vendorData);
      } else {
        await ref.read(woVendorServiceProvider).updateWOVendor(widget.vendor.id, vendorData);
      }

      // Refresh the vendor data
      if (widget.vendorType == 'PO') {
        ref.invalidate(poVendorsProvider);
      } else {
        ref.invalidate(woVendorsProvider);
      }

      // Refresh audit logs
      ref.invalidate(vendorAuditLogsProvider);

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.vendorType} Vendor updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating vendor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAdminDetailView(BuildContext context, dynamic vendor, String vendorType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVendorInfoCard(vendor, vendorType),
          const SizedBox(height: 16),
          _buildComprehensiveAuditCard(vendor),
        ],
      ),
    );
  }

  Widget _buildUserDetailView(BuildContext context, dynamic vendor, String vendorType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVendorInfoCard(vendor, vendorType),
        ],
      ),
    );
  }

  Widget _buildVendorInfoCard(dynamic vendor, String vendorType) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: vendorType == 'PO' ? Colors.blue : Colors.orange,
                  child: Text(
                    vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          vendorType,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: vendorType == 'PO' ? Colors.blue : Colors.orange,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    vendor.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: vendor.isActive ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isEditing) ...[
              _buildEditForm(),
            ] else ...[
              _buildReadOnlyInfo(vendor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Vendor Name *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactPersonController,
          decoration: const InputDecoration(
            labelText: 'Contact Person',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 3,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Active Status'),
          subtitle: Text(_isActive ? 'Vendor is active' : 'Vendor is inactive'),
          value: _isActive,
          onChanged: _isLoading ? null : (value) {
            setState(() {
              _isActive = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildReadOnlyInfo(dynamic vendor) {
    return Column(
      children: [
        _buildInfoRow(Icons.person, 'Contact Person', vendor.contactPerson ?? 'Not specified'),
        _buildInfoRow(Icons.phone, 'Phone', vendor.phoneNumber ?? 'Not specified'),
        _buildInfoRow(Icons.email, 'Email', vendor.email ?? 'Not specified'),
        _buildInfoRow(Icons.location_on, 'Address', vendor.address ?? 'Not specified'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComprehensiveAuditCard(dynamic vendor) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Complete Audit History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAuditLogsList(),
            const SizedBox(height: 8),
            Text(
              'This comprehensive audit trail is only visible to admin users.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditLogsList() {
    final auditLogsAsync = ref.watch(vendorAuditLogsProvider('${widget.vendorType}-${widget.vendor.id}'));

    return auditLogsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                'Error loading audit logs: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (auditLogs) {
        if (auditLogs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No audit history available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: auditLogs.length,
          itemBuilder: (context, index) {
            final log = auditLogs[index];
            return _buildAuditLogItem(log);
          },
        );
      },
    );
  }

  Widget _buildAuditLogItem(VendorAuditLog log) {
    IconData icon;
    Color iconColor;
    String actionText;

    switch (log.action.toLowerCase()) {
      case 'created':
        icon = Icons.add_circle;
        iconColor = Colors.green;
        actionText = 'Created';
        break;
      case 'updated':
        icon = Icons.edit;
        iconColor = Colors.blue;
        actionText = 'Updated';
        break;
      case 'activated':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        actionText = 'Activated';
        break;
      case 'deactivated':
        icon = Icons.cancel;
        iconColor = Colors.red;
        actionText = 'Deactivated';
        break;
      case 'deleted':
        icon = Icons.delete;
        iconColor = Colors.red;
        actionText = 'Deleted';
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
        actionText = log.action.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                actionText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(log.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'By: ${log.performedByName ?? 'System'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (log.changes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildChangeDetails(log.changes),
          ],
          if (log.ipAddress != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'IP: ${log.ipAddress}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChangeDetails(Map<String, dynamic> changes) {
    if (changes.isEmpty) return const SizedBox.shrink();

    final fields = changes['fields'] as Map<String, dynamic>? ?? {};
    if (fields.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Changes:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 4),
          ...fields.entries.map((entry) => _buildFieldChange(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildFieldChange(String fieldName, dynamic changeData) {
    if (changeData is! Map<String, dynamic>) return const SizedBox.shrink();

    final oldValue = changeData['old'];
    final newValue = changeData['new'];

    String displayFieldName = fieldName.replaceAll('_', ' ').toUpperCase();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              displayFieldName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (oldValue != null) ...[
                  Row(
                    children: [
                      const Text(
                        'From: ',
                        style: TextStyle(fontSize: 11, color: Colors.red),
                      ),
                      Expanded(
                        child: Text(
                          oldValue.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                Row(
                  children: [
                    Text(
                      oldValue != null ? 'To: ' : 'Set: ',
                      style: const TextStyle(fontSize: 11, color: Colors.green),
                    ),
                    Expanded(
                      child: Text(
                        newValue?.toString() ?? 'null',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
