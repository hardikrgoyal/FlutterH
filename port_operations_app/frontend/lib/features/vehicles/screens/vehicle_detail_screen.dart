import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/models/vehicle_model.dart';
import '../../auth/auth_service.dart';
import '../vehicle_providers.dart';
import 'add_document_screen.dart';
import 'edit_vehicle_screen.dart';
import 'document_viewer_screen.dart';

class VehicleDetailScreen extends ConsumerStatefulWidget {
  final Vehicle vehicle;
  
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  ConsumerState<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final canEdit = user?.role == 'admin' || user?.role == 'manager' || user?.role == 'accountant';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle.vehicleNumber),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: canEdit ? [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _handleVehicleAction(action, canEdit),
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
          ),
        ] : null,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          indicatorColor: AppColors.white,
          tabs: const [
            Tab(text: 'Vehicle Info', icon: Icon(Icons.info)),
            Tab(text: 'Documents', icon: Icon(Icons.description)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVehicleInfoTab(),
          _buildDocumentsTab(canEdit),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildDocumentSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Vehicle Number', widget.vehicle.vehicleNumber),
            _buildInfoRow('Type', widget.vehicle.vehicleTypeName),
            _buildInfoRow('Ownership', widget.vehicle.ownershipDisplay),
            _buildInfoRow('Status', widget.vehicle.statusDisplay),
            if (widget.vehicle.ownerName != null)
              _buildInfoRow('Owner', widget.vehicle.ownerName!),
            if (widget.vehicle.ownerContact != null)
              _buildInfoRow('Contact', widget.vehicle.ownerContact!),
            if (widget.vehicle.capacity != null)
              _buildInfoRow('Capacity', widget.vehicle.capacity!),
            if (widget.vehicle.makeModel != null)
              _buildInfoRow('Make & Model', widget.vehicle.makeModel!),
            if (widget.vehicle.yearOfManufacture != null)
              _buildInfoRow('Year', widget.vehicle.yearOfManufacture.toString()),
            if (widget.vehicle.chassisNumber != null)
              _buildInfoRow('Chassis Number', widget.vehicle.chassisNumber!),
            if (widget.vehicle.engineNumber != null)
              _buildInfoRow('Engine Number', widget.vehicle.engineNumber!),
            if (widget.vehicle.remarks != null)
              _buildInfoRow('Remarks', widget.vehicle.remarks!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Document Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryItem(
                  'Active',
                  widget.vehicle.activeDocumentsCount,
                  AppColors.success,
                ),
                _buildSummaryItem(
                  'Expiring Soon',
                  widget.vehicle.expiringSoonCount,
                  AppColors.warning,
                ),
                _buildSummaryItem(
                  'Expired',
                  widget.vehicle.expiredDocumentsCount,
                  AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsTab(bool canEdit) {
    final documentsAsync = ref.watch(vehicleDocumentsProvider(widget.vehicle.id));

    return documentsAsync.when(
      data: (documentGroups) => _buildDocumentsList(documentGroups, canEdit),
      loading: () => const LoadingWidget(),
      error: (error, stack) => AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.refresh(vehicleDocumentsProvider(widget.vehicle.id)),
      ),
    );
  }

  Widget _buildDocumentsList(List<VehicleDocumentGroup> documentGroups, bool canEdit) {
    return Column(
      children: [
        if (canEdit)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToAddDocument(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Document'),
              ),
            ),
          ),
        Expanded(
          child: documentGroups.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: AppColors.textSecondary),
                      SizedBox(height: 16),
                      Text('No documents found', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: documentGroups.length,
                  itemBuilder: (context, index) {
                    final group = documentGroups[index];
                    return _buildDocumentGroupCard(group, canEdit);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDocumentGroupCard(VehicleDocumentGroup group, bool canEdit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          group.typeDisplay,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: group.current != null
            ? Text('Expires: ${group.current!.expiryDate}')
            : const Text('No active document'),
        leading: Icon(
          _getDocumentIcon(group.type),
          color: group.current?.isExpiringSoon == true ? AppColors.warning : AppColors.primary,
        ),
        trailing: group.current?.isExpiringSoon == true
            ? const Icon(Icons.warning, color: AppColors.warning)
            : null,
        children: [
          if (group.current != null) ...[
            _buildCurrentDocumentTile(group.current!, canEdit),
            if (group.history.length > 1) const Divider(),
          ],
          if (group.history.length > 1) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Document History',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ...group.history.where((doc) => doc.status == 'expired').map(
              (doc) => _buildHistoryDocumentTile(doc),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentDocumentTile(VehicleDocument document, bool canEdit) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        document.documentNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Expires: ${document.expiryDate}'),
                      Text(
                        '${document.daysUntilExpiry} days remaining',
                        style: TextStyle(
                          color: document.daysUntilExpiry <= 7 ? AppColors.error : AppColors.textSecondary,
                          fontWeight: document.daysUntilExpiry <= 7 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'renew',
                        child: Row(
                          children: [
                            Icon(Icons.refresh),
                            SizedBox(width: 8),
                            Text('Renew'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'renew') {
                        _navigateToRenewDocument(document);
                      } else if (value == 'edit') {
                        _navigateToEditDocument(document);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // User tracking information
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
              ],
            ),
            // File attachment information
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
    );
  }

  Widget _buildHistoryDocumentTile(VehicleDocument document) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.documentNumber,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Expired: ${document.expiryDate}',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (document.documentFile != null)
                  TextButton(
                    onPressed: () => _viewFile(document),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text('View', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // User tracking for expired documents
            Row(
              children: [
                Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Added by: ${document.addedByName}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                if (document.renewedByName != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.refresh, size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Renewed by: ${document.renewedByName}',
                    style: const TextStyle(fontSize: 11, color: AppColors.warning),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String documentType) {
    switch (documentType) {
      case 'insurance':
        return Icons.security;
      case 'puc':
        return Icons.eco;
      case 'rc':
        return Icons.assignment;
      case 'fitness':
        return Icons.health_and_safety;
      case 'road_tax':
        return Icons.money;
      case 'permit':
        return Icons.verified;
      case 'fastag':
        return Icons.toll;
      default:
        return Icons.description;
    }
  }

  void _navigateToAddDocument() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDocumentScreen(vehicle: widget.vehicle),
      ),
    ).then((_) {
      ref.refresh(vehicleDocumentsProvider(widget.vehicle.id));
    });
  }

  void _navigateToRenewDocument(VehicleDocument document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDocumentScreen(
          vehicle: widget.vehicle,
          renewDocument: document,
        ),
      ),
    ).then((_) {
      ref.refresh(vehicleDocumentsProvider(widget.vehicle.id));
    });
  }

  void _navigateToEditDocument(VehicleDocument document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDocumentScreen(
          vehicle: widget.vehicle,
          editDocument: document,
        ),
      ),
    ).then((_) {
      ref.refresh(vehicleDocumentsProvider(widget.vehicle.id));
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

  void _handleVehicleAction(String action, bool canEdit) {
    switch (action) {
      case 'edit':
        _editVehicle();
        break;
      case 'delete':
        _confirmDeleteVehicle();
        break;
    }
  }

  void _editVehicle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVehicleScreen(vehicle: widget.vehicle),
      ),
    );

    // Pop back to vehicles list if vehicle was updated
    if (result == true && mounted) {
      Navigator.pop(context, true); // Return to vehicle list with refresh signal
    }
  }

  void _confirmDeleteVehicle() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete vehicle "${widget.vehicle.vehicleNumber}"?'),
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
              _deleteVehicle();
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

  void _deleteVehicle() async {
    try {
      await ref.read(vehicleServiceProvider).deleteVehicle(widget.vehicle.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle "${widget.vehicle.vehicleNumber}" deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        // Pop back to vehicles list
        Navigator.pop(context, true); // Return with refresh signal
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
} 