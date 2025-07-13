import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/equipment_rate_master_model.dart';
import '../services/equipment_rate_master_service.dart';
import '../../../shared/models/vehicle_type_model.dart';
import '../../../shared/models/work_type_model.dart';
import '../../../shared/models/party_master_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/auth_service.dart';

class EquipmentRateMasterListScreen extends ConsumerStatefulWidget {
  const EquipmentRateMasterListScreen({super.key});

  @override
  ConsumerState<EquipmentRateMasterListScreen> createState() =>
      _EquipmentRateMasterListScreenState();
}

class _EquipmentRateMasterListScreenState
    extends ConsumerState<EquipmentRateMasterListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedContractType;
  int? _selectedPartyId;
  int? _selectedVehicleTypeId;
  int? _selectedWorkTypeId;

  final List<String> _contractTypes = ['hours', 'shift', 'tonnes', 'fixed'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(equipmentRateMasterServiceProvider.notifier).loadEquipmentRateMasters(
          partyId: _selectedPartyId,
          vehicleTypeId: _selectedVehicleTypeId,
          workTypeId: _selectedWorkTypeId,
          contractType: _selectedContractType,
        );
  }

  @override
  Widget build(BuildContext context) {
    final rateMasterState = ref.watch(equipmentRateMasterServiceProvider);
    final authState = ref.watch(authStateProvider);

    // Check if user has permission (only admin and manager)
    if (authState.user?.role != 'admin' && authState.user?.role != 'manager') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Equipment Rate Master'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        drawer: const AppDrawer(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Only administrators and managers can access rate master.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Rate Master'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by party, vehicle type, or work type...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filters row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Contract Type filter
                      _buildFilterChip(
                        'Contract Type',
                        _selectedContractType ?? 'All',
                        () => _showContractTypeFilter(),
                      ),
                      const SizedBox(width: 8),
                      // Clear filters
                      if (_selectedContractType != null ||
                          _selectedPartyId != null ||
                          _selectedVehicleTypeId != null ||
                          _selectedWorkTypeId != null)
                        FilterChip(
                          label: const Text('Clear Filters'),
                          onSelected: (_) => _clearFilters(),
                          backgroundColor: Colors.red.shade50,
                          selectedColor: Colors.red.shade100,
                          side: BorderSide(color: Colors.red.shade300),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: rateMasterState.isLoading
                ? const LoadingWidget()
                : rateMasterState.error != null
                                         ? AppErrorWidget(
                         message: rateMasterState.error!,
                         onRetry: _loadData,
                       )
                    : _buildRateMasterList(rateMasterState.rateMasters),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRateMasterDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    return FilterChip(
      label: Text('$label: $value'),
      onSelected: (_) => onTap(),
      backgroundColor: Colors.blue.shade50,
      selectedColor: Colors.blue.shade100,
      side: BorderSide(color: Colors.blue.shade300),
    );
  }

  Widget _buildRateMasterList(List<EquipmentRateMaster> rateMasters) {
    final filteredRateMasters = _filterRateMasters(rateMasters);

    if (filteredRateMasters.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No rate masters found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Add rate masters to get started',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRateMasters.length,
      itemBuilder: (context, index) {
        final rateMaster = filteredRateMasters[index];
        return _buildRateMasterCard(rateMaster);
      },
    );
  }

  List<EquipmentRateMaster> _filterRateMasters(List<EquipmentRateMaster> rateMasters) {
    return rateMasters.where((rateMaster) {
      final matchesSearch = _searchQuery.isEmpty ||
          rateMaster.partyName.toLowerCase().contains(_searchQuery) ||
          rateMaster.vehicleTypeName.toLowerCase().contains(_searchQuery) ||
          rateMaster.workTypeName.toLowerCase().contains(_searchQuery) ||
          rateMaster.contractTypeDisplay.toLowerCase().contains(_searchQuery);

      return matchesSearch;
    }).toList();
  }

  Widget _buildRateMasterCard(EquipmentRateMaster rateMaster) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rateMaster.partyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${rateMaster.vehicleTypeName} - ${rateMaster.workTypeName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getContractTypeColor(rateMaster.contractType),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rateMaster.contractTypeDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Rate
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rate:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    rateMaster.formattedRate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${rateMaster.formattedCreatedAt}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showEditRateMasterDialog(rateMaster),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(rateMaster),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getContractTypeColor(String contractType) {
    switch (contractType.toLowerCase()) {
      case 'hours':
        return Colors.blue;
      case 'shift':
        return Colors.orange;
      case 'tonnes':
        return Colors.purple;
      case 'fixed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showContractTypeFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Contract Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All'),
              onTap: () {
                setState(() {
                  _selectedContractType = null;
                });
                _loadData();
                Navigator.pop(context);
              },
            ),
            ..._contractTypes.map((type) => ListTile(
                  title: Text(type.toUpperCase()),
                  onTap: () {
                    setState(() {
                      _selectedContractType = type;
                    });
                    _loadData();
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedContractType = null;
      _selectedPartyId = null;
      _selectedVehicleTypeId = null;
      _selectedWorkTypeId = null;
    });
    _loadData();
  }

  void _showAddRateMasterDialog() {
    showDialog(
      context: context,
      builder: (context) => EquipmentRateMasterDialog(
        onSaved: () {
          _loadData();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditRateMasterDialog(EquipmentRateMaster rateMaster) {
    showDialog(
      context: context,
      builder: (context) => EquipmentRateMasterDialog(
        rateMaster: rateMaster,
        onSaved: () {
          _loadData();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDeleteConfirmation(EquipmentRateMaster rateMaster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rate Master'),
        content: Text(
          'Are you sure you want to delete this rate master?\n\n${rateMaster.displayTitle}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(equipmentRateMasterServiceProvider.notifier)
                  .deleteEquipmentRateMaster(rateMaster.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rate master deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Rate Master Dialog for Add/Edit
class EquipmentRateMasterDialog extends ConsumerStatefulWidget {
  final EquipmentRateMaster? rateMaster;
  final VoidCallback onSaved;

  const EquipmentRateMasterDialog({
    super.key,
    this.rateMaster,
    required this.onSaved,
  });

  @override
  ConsumerState<EquipmentRateMasterDialog> createState() =>
      _EquipmentRateMasterDialogState();
}

class _EquipmentRateMasterDialogState
    extends ConsumerState<EquipmentRateMasterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();

  int? _selectedPartyId;
  int? _selectedVehicleTypeId;
  int? _selectedWorkTypeId;
  String? _selectedContractType;

  bool _isLoading = false;

  final List<String> _contractTypes = ['hours', 'shift', 'tonnes', 'fixed'];

  @override
  void initState() {
    super.initState();
    if (widget.rateMaster != null) {
      _selectedPartyId = widget.rateMaster!.party;
      _selectedVehicleTypeId = widget.rateMaster!.vehicleType;
      _selectedWorkTypeId = widget.rateMaster!.workType;
      _selectedContractType = widget.rateMaster!.contractType;
      _rateController.text = widget.rateMaster!.rate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.rateMaster == null ? 'Add Rate Master' : 'Edit Rate Master'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Party Dropdown (simplified for demo)
              DropdownButtonFormField<String>(
                value: _selectedContractType,
                decoration: const InputDecoration(
                  labelText: 'Contract Type',
                  border: OutlineInputBorder(),
                ),
                items: _contractTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedContractType = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select contract type' : null,
              ),
              const SizedBox(height: 16),
              
              // Rate field
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(
                  labelText: 'Rate (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter rate';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Rate must be greater than 0';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveRateMaster,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.rateMaster == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  Future<void> _saveRateMaster() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final rate = double.parse(_rateController.text);

    bool success = false;
    if (widget.rateMaster == null) {
      // For demo purposes, using placeholder values for party, vehicle type, work type
      success = await ref
          .read(equipmentRateMasterServiceProvider.notifier)
          .createEquipmentRateMaster(
            partyId: 1, // Placeholder
            vehicleTypeId: 1, // Placeholder
            workTypeId: 1, // Placeholder
            contractType: _selectedContractType!,
            rate: rate,
          );
    } else {
      success = await ref
          .read(equipmentRateMasterServiceProvider.notifier)
          .updateEquipmentRateMaster(
            id: widget.rateMaster!.id,
            partyId: widget.rateMaster!.party,
            vehicleTypeId: widget.rateMaster!.vehicleType,
            workTypeId: widget.rateMaster!.workType,
            contractType: _selectedContractType!,
            rate: rate,
          );
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.rateMaster == null
                ? 'Rate master created successfully'
                : 'Rate master updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }
} 