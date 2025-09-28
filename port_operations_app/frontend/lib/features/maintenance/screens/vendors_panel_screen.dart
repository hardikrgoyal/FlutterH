import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../services/po_vendor_service.dart';
import '../services/wo_vendor_service.dart';
import '../../../shared/models/po_vendor_model.dart';
import '../../../shared/models/wo_vendor_model.dart';
import '../../auth/auth_service.dart';
import 'vendor_detail/vendor_detail_screen.dart';

class VendorsPanelScreen extends ConsumerStatefulWidget {
  const VendorsPanelScreen({super.key});

  @override
  ConsumerState<VendorsPanelScreen> createState() => _VendorsPanelScreenState();
}

class _VendorsPanelScreenState extends ConsumerState<VendorsPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToVendorDetail(BuildContext context, dynamic vendor, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendorDetailScreen(
          vendor: vendor,
          vendorType: type,
        ),
      ),
    );
  }

  void _showAddVendorDialog() {
    final currentType = _tabController.index == 0 ? 'PO' : 'WO';
    showDialog(
      context: context,
      builder: (context) => AddVendorDialog(
        type: currentType,
        onVendorAdded: () {
          if (currentType == 'PO') {
            ref.invalidate(poVendorsProvider);
          } else {
            ref.invalidate(woVendorsProvider);
          }
        },
      ),
    );
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

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Vendors Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.shopping_cart),
              text: 'PO Vendors',
            ),
            Tab(
              icon: Icon(Icons.build),
              text: 'WO Vendors',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          POVendorsTab(onVendorTap: _navigateToVendorDetail),
          WOVendorsTab(onVendorTap: _navigateToVendorDetail),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVendorDialog,
        backgroundColor: AppColors.primary,
        tooltip: 'Add Vendor',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class POVendorsTab extends ConsumerWidget {
  final Function(BuildContext, dynamic, String) onVendorTap;

  const POVendorsTab({super.key, required this.onVendorTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poVendorsAsync = ref.watch(poVendorsProvider);

    return poVendorsAsync.when(
      data: (vendors) {
        if (vendors.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No PO Vendors found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the + button to add a new vendor',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final vendor = vendors[index];
            return _buildVendorCard(context, ref, vendor, 'PO');
          },
        );
      },
      loading: () => const LoadingWidget(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading vendors: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(poVendorsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, WidgetRef ref, POVendor vendor, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onVendorTap(context, vendor, type),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            vendor.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vendor.contactPerson?.isNotEmpty ?? false)
                Text('Contact: ${vendor.contactPerson}'),
              if (vendor.phoneNumber?.isNotEmpty ?? false)
                Text('Phone: ${vendor.phoneNumber}'),
              if (vendor.email?.isNotEmpty ?? false)
                Text('Email: ${vendor.email}'),
            ],
          ),
          trailing: Chip(
            label: Text(
              vendor.isActive ? 'Active' : 'Inactive',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: vendor.isActive ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}

class WOVendorsTab extends ConsumerWidget {
  final Function(BuildContext, dynamic, String) onVendorTap;

  const WOVendorsTab({super.key, required this.onVendorTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final woVendorsAsync = ref.watch(woVendorsProvider);

    return woVendorsAsync.when(
      data: (vendors) {
        if (vendors.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No WO Vendors found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the + button to add a new vendor',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final vendor = vendors[index];
            return _buildVendorCard(context, ref, vendor, 'WO');
          },
        );
      },
      loading: () => const LoadingWidget(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading vendors: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(woVendorsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, WidgetRef ref, WOVendor vendor, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onVendorTap(context, vendor, type),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            vendor.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vendor.contactPerson?.isNotEmpty ?? false)
                Text('Contact: ${vendor.contactPerson}'),
              if (vendor.phoneNumber?.isNotEmpty ?? false)
                Text('Phone: ${vendor.phoneNumber}'),
              if (vendor.email?.isNotEmpty ?? false)
                Text('Email: ${vendor.email}'),
            ],
          ),
          trailing: Chip(
            label: Text(
              vendor.isActive ? 'Active' : 'Inactive',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: vendor.isActive ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}

// Add Vendor Dialog
class AddVendorDialog extends ConsumerStatefulWidget {
  final String type;
  final VoidCallback onVendorAdded;

  const AddVendorDialog({
    super.key,
    required this.type,
    required this.onVendorAdded,
  });

  @override
  ConsumerState<AddVendorDialog> createState() => _AddVendorDialogState();
}

class _AddVendorDialogState extends ConsumerState<AddVendorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

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
    return AlertDialog(
      title: Text('Add ${widget.type} Vendor'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Vendor Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vendor name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addVendor,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Vendor'),
        ),
      ],
    );
  }

  Future<void> _addVendor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.type == 'PO') {
        await ref.read(poVendorServiceProvider).createPOVendor({
          'name': _nameController.text.trim(),
          'contact_person': _contactPersonController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'is_active': _isActive,
        });
      } else {
        await ref.read(woVendorServiceProvider).createWOVendor({
          'name': _nameController.text.trim(),
          'contact_person': _contactPersonController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'is_active': _isActive,
        });
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onVendorAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.type} Vendor added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding vendor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
