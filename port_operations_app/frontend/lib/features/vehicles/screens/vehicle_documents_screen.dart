import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/models/vehicle_model.dart';
import '../../../shared/models/vehicle_type_model.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/auth_service.dart';
import '../vehicle_providers.dart';
import 'vehicle_detail_screen.dart';
import 'add_vehicle_screen.dart';
import 'edit_vehicle_screen.dart';
import 'document_viewer_screen.dart';

class VehicleDocumentsScreen extends ConsumerStatefulWidget {
  const VehicleDocumentsScreen({super.key});

  @override
  ConsumerState<VehicleDocumentsScreen> createState() => _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState extends ConsumerState<VehicleDocumentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _filters = {};

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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final canEdit = user?.role == 'admin' || user?.role == 'manager' || user?.role == 'accountant';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Documents'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          indicatorColor: AppColors.white,
          tabs: const [
            Tab(text: 'All Vehicles', icon: Icon(Icons.directions_car)),
            Tab(text: 'Expiring Soon', icon: Icon(Icons.warning_amber)),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVehiclesTab(canEdit),
          _buildExpiringSoonTab(),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () => _navigateToAddVehicle(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: AppColors.white),
            )
          : null,
    );
  }

  Widget _buildVehiclesTab(bool canEdit) {
    final vehiclesAsync = ref.watch(vehiclesProvider(_filters));

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: vehiclesAsync.when(
            data: (vehicles) => _buildVehiclesList(vehicles, canEdit),
            loading: () => const LoadingWidget(),
            error: (error, stack) => AppErrorWidget(
              message: error.toString(),
              onRetry: () => ref.refresh(vehiclesProvider(_filters)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiringSoonTab() {
    final expiringSoonAsync = ref.watch(expiringSoonDocumentsProvider);

    return expiringSoonAsync.when(
      data: (documents) => _buildExpiringSoonList(documents),
      loading: () => const LoadingWidget(),
      error: (error, stack) => AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.refresh(expiringSoonDocumentsProvider),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              value: _filters['status'],
              items: const [
                DropdownMenuItem(value: null, child: Text('All Status')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
              ],
              onChanged: (value) {
                setState(() {
                  _filters['status'] = value;
                });
                ref.refresh(vehiclesProvider(_filters));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Ownership',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              value: _filters['ownership'],
              items: const [
                DropdownMenuItem(value: null, child: Text('All Types')),
                DropdownMenuItem(value: 'owned', child: Text('Company Owned')),
                DropdownMenuItem(value: 'hired', child: Text('Hired/Contract')),
              ],
              onChanged: (value) {
                setState(() {
                  _filters['ownership'] = value;
                });
                ref.refresh(vehiclesProvider(_filters));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclesList(List<Vehicle> vehicles, bool canEdit) {
    if (vehicles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('No vehicles found', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return _buildVehicleCard(vehicle, canEdit);
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle, bool canEdit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToVehicleDetail(vehicle),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.vehicleNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          vehicle.vehicleTypeName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildStatusChip(vehicle.status, vehicle.statusDisplay),
                      if (canEdit) ...[
                        const SizedBox(width: 8),
                        _buildVehicleActionsMenu(vehicle),
                      ],
                    ],
                  ),
                ],
              ),
              if (vehicle.ownerName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      vehicle.ownerName!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDocumentBadge(
                    'Active',
                    vehicle.activeDocumentsCount,
                    AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _buildDocumentBadge(
                    'Expiring',
                    vehicle.expiringSoonCount,
                    AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  _buildDocumentBadge(
                    'Expired',
                    vehicle.expiredDocumentsCount,
                    AppColors.error,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, String statusDisplay) {
    Color color;
    switch (status) {
      case 'active':
        color = AppColors.success;
        break;
      case 'inactive':
        color = AppColors.textSecondary;
        break;
      case 'maintenance':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        statusDisplay,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDocumentBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiringSoonList(List<VehicleDocument> documents) {
    if (documents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: AppColors.success),
            SizedBox(height: 16),
            Text('No documents expiring soon', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return _buildDocumentCard(document);
      },
    );
  }

  Widget _buildDocumentCard(VehicleDocument document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToVehicleDetailFromDocument(document),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${document.vehicleNumber} - ${document.documentTypeDisplay}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          document.documentNumber,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildExpiryChip(document),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Expires: ${document.expiryDate}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${document.daysUntilExpiry} days',
                    style: TextStyle(
                      fontSize: 12,
                      color: document.daysUntilExpiry <= 7 ? AppColors.error : AppColors.textSecondary,
                      fontWeight: document.daysUntilExpiry <= 7 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Added by: ${document.addedByName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (document.renewedByName != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.refresh, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Renewed by: ${document.renewedByName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ],
                  if (document.updatedByName != null && document.renewedByName == null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.edit, size: 16, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      'Updated by: ${document.updatedByName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ],
                ],
              ),
              if (document.documentFile != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_file, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Document attached',
                        style: const TextStyle(fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _viewFile(document),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      child: const Text('View'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpiryChip(VehicleDocument document) {
    Color color;
    String text;
    
    if (document.isExpired) {
      color = AppColors.error;
      text = 'Expired';
    } else if (document.daysUntilExpiry <= 7) {
      color = AppColors.error;
      text = 'Urgent';
    } else if (document.isExpiringSoon) {
      color = AppColors.warning;
      text = 'Soon';
    } else {
      color = AppColors.success;
      text = 'Valid';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _navigateToVehicleDetail(Vehicle vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailScreen(vehicle: vehicle),
      ),
    );
  }

  void _navigateToAddVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddVehicleScreen(),
      ),
    ).then((_) {
      // Refresh the list when returning
      ref.refresh(vehiclesProvider(_filters));
    });
  }

  void _viewFile(VehicleDocument document) {
    if (document.documentFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file attached to this document'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerScreen(
          fileUrl: document.documentFile!,
          documentNumber: document.documentNumber,
          documentType: document.documentTypeDisplay,
        ),
      ),
    );
  }

  Widget _buildVehicleActionsMenu(Vehicle vehicle) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (action) => _handleVehicleAction(action, vehicle),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Edit Vehicle'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: AppColors.error),
              SizedBox(width: 8),
              Text('Delete Vehicle'),
            ],
          ),
        ),
      ],
    );
  }

  void _handleVehicleAction(String action, Vehicle vehicle) {
    switch (action) {
      case 'edit':
        _editVehicle(vehicle);
        break;
      case 'delete':
        _confirmDeleteVehicle(vehicle);
        break;
    }
  }

  void _editVehicle(Vehicle vehicle) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVehicleScreen(vehicle: vehicle),
      ),
    );

    // Refresh the list if vehicle was updated
    if (result == true) {
      ref.refresh(vehiclesProvider(_filters));
    }
  }

  void _confirmDeleteVehicle(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete vehicle "${vehicle.vehicleNumber}"?'),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone. All associated documents will also be deleted.',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVehicle(vehicle);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteVehicle(Vehicle vehicle) async {
    try {
      await ref.read(vehicleServiceProvider).deleteVehicle(vehicle.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle "${vehicle.vehicleNumber}" deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh the list
        ref.refresh(vehiclesProvider(_filters));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete vehicle: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToVehicleDetailFromDocument(VehicleDocument document) async {
    // Find the vehicle from the current vehicles list
    final vehiclesAsync = ref.read(vehiclesProvider(_filters));
    vehiclesAsync.when(
      data: (vehicles) async {
        final vehicle = vehicles.firstWhere(
          (v) => v.id == document.vehicle,
          orElse: () => throw Exception('Vehicle not found'),
        );
        
        if (mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailScreen(vehicle: vehicle),
            ),
          );
          
          // Refresh the list if there were changes
          if (result == true) {
            ref.refresh(vehiclesProvider(_filters));
            ref.refresh(expiringSoonDocumentsProvider);
          }
        }
      },
      loading: () => {},
      error: (error, stack) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open vehicle details: Vehicle not found'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }
} 