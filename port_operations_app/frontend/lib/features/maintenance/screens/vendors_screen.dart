import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/models/vendor_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../services/vendor_service.dart';
import '../../auth/auth_service.dart';

class VendorsScreen extends ConsumerStatefulWidget {
  const VendorsScreen({super.key});

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Vendors'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(user),
      floatingActionButton: user?.canManageVendors == true
          ? FloatingActionButton(
              onPressed: () {
                _showAddVendorDialog();
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(User? user) {
    final vendorsAsync = ref.watch(vendorsProvider);

    return vendorsAsync.when(
      data: (vendors) => _buildVendorsList(vendors, user),
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
              onPressed: () => ref.invalidate(vendorsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorsList(List<Vendor> vendors, User? user) {
    if (vendors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No vendors found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first vendor',
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
        ref.invalidate(vendorsProvider);
      },
      child: ListView.builder(
        itemCount: vendors.length,
        itemBuilder: (context, index) {
          final vendor = vendors[index];
          return _buildVendorCard(vendor, user);
        },
      ),
    );
  }

  Widget _buildVendorCard(Vendor vendor, User? user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          _showVendorDetails(vendor);
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
                      vendor.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: vendor.isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vendor.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (vendor.contactPerson?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.person, 'Contact', vendor.contactPerson!),
              ],
              if (vendor.phoneNumber?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                _buildInfoRow(Icons.phone, 'Phone', vendor.phoneNumber!),
              ],
              if (vendor.email?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                _buildInfoRow(Icons.email, 'Email', vendor.email!),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Added: ${vendor.createdAt}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (user?.canManageVendors == true)
                    PopupMenuButton<String>(
                      onSelected: (String action) {
                        _handleVendorAction(action, vendor);
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: vendor.isActive ? 'deactivate' : 'activate',
                          child: Text(vendor.isActive ? 'Deactivate' : 'Activate'),
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

  void _showVendorDetails(Vendor vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vendor.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Contact Person', vendor.contactPerson ?? 'Not provided'),
              _buildDetailRow('Phone', vendor.phoneNumber ?? 'Not provided'),
              _buildDetailRow('Email', vendor.email ?? 'Not provided'),
              _buildDetailRow('Address', vendor.address ?? 'Not provided'),
              _buildDetailRow('Status', vendor.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Created By', vendor.createdByName ?? 'Unknown'),
              _buildDetailRow('Created At', vendor.createdAt),
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

  void _handleVendorAction(String action, Vendor vendor) {
    switch (action) {
      case 'edit':
        _showEditVendorDialog(vendor);
        break;
      case 'activate':
      case 'deactivate':
        _toggleVendorStatus(vendor);
        break;
    }
  }

  void _showAddVendorDialog() {
    _showVendorDialog();
  }

  void _showEditVendorDialog(Vendor vendor) {
    _showVendorDialog(vendor: vendor);
  }

  void _showVendorDialog({Vendor? vendor}) {
    final nameController = TextEditingController(text: vendor?.name ?? '');
    final contactController = TextEditingController(text: vendor?.contactPerson ?? '');
    final phoneController = TextEditingController(text: vendor?.phoneNumber ?? '');
    final emailController = TextEditingController(text: vendor?.email ?? '');
    final addressController = TextEditingController(text: vendor?.address ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vendor == null ? 'Add Vendor' : 'Edit Vendor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Vendor Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter vendor name')),
                );
                return;
              }

              Navigator.pop(context);
              
              try {
                final vendorService = ref.read(vendorServiceProvider);
                final vendorData = {
                  'name': name,
                  'contact_person': contactController.text.trim().isNotEmpty 
                      ? contactController.text.trim() : null,
                  'phone_number': phoneController.text.trim().isNotEmpty 
                      ? phoneController.text.trim() : null,
                  'email': emailController.text.trim().isNotEmpty 
                      ? emailController.text.trim() : null,
                  'address': addressController.text.trim().isNotEmpty 
                      ? addressController.text.trim() : null,
                };

                if (vendor == null) {
                  await vendorService.createVendor(vendorData);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vendor created successfully')),
                  );
                } else {
                  await vendorService.updateVendor(vendor.id, vendorData);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vendor updated successfully')),
                  );
                }
                
                ref.invalidate(vendorsProvider);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(vendor == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _toggleVendorStatus(Vendor vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${vendor.isActive ? 'Deactivate' : 'Activate'} Vendor'),
        content: Text(
          'Are you sure you want to ${vendor.isActive ? 'deactivate' : 'activate'} ${vendor.name}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final vendorService = ref.read(vendorServiceProvider);
                await vendorService.updateVendor(vendor.id, {
                  'is_active': !vendor.isActive,
                });
                ref.invalidate(vendorsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Vendor ${vendor.isActive ? 'deactivated' : 'activated'} successfully'
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(vendor.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }
} 