import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/models/transport_detail_model.dart';
import '../../../shared/models/cargo_operation_model.dart';
import '../../../shared/widgets/app_drawer.dart';

import '../services/transport_service.dart';
import '../../auth/auth_service.dart';

class TransportFormScreen extends ConsumerStatefulWidget {
  final int? transportId;

  const TransportFormScreen({
    super.key,
    this.transportId,
  });

  @override
  ConsumerState<TransportFormScreen> createState() => _TransportFormScreenState();
}

class _TransportFormScreenState extends ConsumerState<TransportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _billNoController = TextEditingController();
  final _rateController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  TransportDetail? _transport;
  List<CargoOperation> _operations = [];
  double _calculatedCost = 0.0;

  DateTime _selectedDate = DateTime.now();
  int? _selectedOperationId;
  int? _selectedVehicleTypeId;
  int? _selectedPartyId;
  String _selectedContractType = 'per_trip';

  final List<String> _contractTypes = ['per_trip', 'per_mt', 'daily', 'lumpsum'];
  final Map<String, String> _contractTypeLabels = {
    'per_trip': 'Per Trip',
    'per_mt': 'Per MT',
    'daily': 'Daily',
    'lumpsum': 'Lumpsum',
  };

  bool get _isEditing => widget.transportId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Add listeners for calculating cost
    _quantityController.addListener(_calculateCost);
    _rateController.addListener(_calculateCost);
    
    // Load master data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transportDetailProvider.notifier).loadMasterData();
    });
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _quantityController.dispose();
    _billNoController.dispose();
    _rateController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load operations
      await ref.read(transportDetailProvider.notifier).loadOperations();
      final state = ref.read(transportDetailProvider);
      final operations = state.operations;

      if (!mounted) return;
      setState(() {
        _operations = operations;
      });

      // Load transport detail if editing
      if (_isEditing) {
        final transport = await ref.read(transportDetailProvider.notifier).getTransportDetail(widget.transportId!);
        if (!mounted) return;
        
        setState(() {
          _transport = transport;
          _populateForm();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateForm() {
    if (_transport == null) return;

    final formatter = DateFormat('yyyy-MM-dd');
    
    _selectedDate = formatter.parse(_transport!.date);
    _selectedOperationId = _transport!.operation;
    _selectedContractType = _transport!.contractType;
    
    // Find vehicle type ID from name
    final state = ref.read(transportDetailProvider);
    final vehicleType = state.vehicleTypes.where((vt) => vt.name == _transport!.vehicle).firstOrNull;
    _selectedVehicleTypeId = vehicleType?.id;
    
    // Find party ID from name
    final party = state.parties.where((p) => p.name == _transport!.partyName).firstOrNull;
    _selectedPartyId = party?.id;
    
    _vehicleNumberController.text = _transport!.vehicleNumber;
    _quantityController.text = _transport!.quantity;
    _billNoController.text = _transport!.billNo ?? '';
    _rateController.text = _transport!.rate;
    _remarksController.text = _transport!.remarks ?? '';
    
    _calculateCost();
  }

  void _calculateCost() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    
    setState(() {
      _calculatedCost = quantity * rate;
    });
  }

  String _getVehicleTypeName() {
    if (_selectedVehicleTypeId == null) return '';
    final state = ref.read(transportDetailProvider);
    final vehicleType = state.vehicleTypes.where((vt) => vt.id == _selectedVehicleTypeId).firstOrNull;
    return vehicleType?.name ?? '';
  }

  String _getPartyName() {
    if (_selectedPartyId == null) return '';
    final state = ref.read(transportDetailProvider);
    final party = state.parties.where((p) => p.id == _selectedPartyId).firstOrNull;
    return party?.name ?? '';
  }

  Future<void> _saveTransport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final transportDetail = TransportDetail(
        id: _transport?.id ?? 0,
        operation: _selectedOperationId!,
        operationName: _operations.firstWhere((op) => op.id == _selectedOperationId!).operationName,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        vehicle: _getVehicleTypeName(),
        vehicleNumber: _vehicleNumberController.text.trim(),
        contractType: _selectedContractType,
        quantity: _quantityController.text.trim(),
        partyName: _getPartyName(),
        billNo: _billNoController.text.trim().isEmpty ? null : _billNoController.text.trim(),
        rate: _rateController.text.trim(),
        cost: _calculatedCost.toStringAsFixed(2),
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        createdBy: 1,
        createdByName: ref.read(authStateProvider).user?.username ?? '',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      bool success;
      if (_isEditing) {
        success = await ref.read(transportDetailProvider.notifier).updateTransportDetail(widget.transportId!, transportDetail);
      } else {
        success = await ref.read(transportDetailProvider.notifier).createTransportDetail(transportDetail);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transport detail ${_isEditing ? 'updated' : 'created'} successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        final error = ref.read(transportDetailProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to ${_isEditing ? 'update' : 'create'} transport detail'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final transportState = ref.watch(transportDetailProvider);

    // Check if user can add new items (managers and admins)
    final canAddNew = user?.role == 'manager' || user?.role == 'admin';

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
        drawer: AppDrawer(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transport Detail' : 'Add Transport Detail'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton(
              onPressed: _saveTransport,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error display
                        if (transportState.error != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    transportState.error!,
                                    style: TextStyle(color: Colors.red.shade600),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => ref.read(transportDetailProvider.notifier).clearError(),
                                  icon: const Icon(Icons.close),
                                  iconSize: 20,
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Operation Details Section
                        _buildSectionHeader('Operation Details', Icons.work_outline),
                        const SizedBox(height: 12),
                        _buildOperationDropdown(),
                        const SizedBox(height: 16),
                        _buildDateField(),
                        const SizedBox(height: 24),

                        // Vehicle Details Section
                        _buildSectionHeader('Vehicle Details', Icons.local_shipping),
                        const SizedBox(height: 12),
                        _buildVehicleTypeDropdown(transportState, canAddNew),
                        const SizedBox(height: 16),
                        _buildVehicleNumberField(),
                        const SizedBox(height: 24),

                        // Contract Details Section
                        _buildSectionHeader('Contract Details', Icons.description),
                        const SizedBox(height: 12),
                        _buildContractTypeDropdown(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildQuantityField()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildRateField()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCalculatedCostCard(),
                        const SizedBox(height: 24),

                        // Party Details Section
                        _buildSectionHeader('Party Details', Icons.business),
                        const SizedBox(height: 12),
                        _buildPartyDropdown(transportState, canAddNew),
                        const SizedBox(height: 16),
                        _buildBillNoField(),
                        const SizedBox(height: 24),

                        // Additional Information Section
                        _buildSectionHeader('Additional Information', Icons.note),
                        const SizedBox(height: 12),
                        _buildRemarksField(),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveTransport,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator()
                                : Text(
                                    _isEditing ? 'Update Transport Detail' : 'Create Transport Detail',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildOperationDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedOperationId,
      decoration: const InputDecoration(
        labelText: 'Operation Name *',
        hintText: 'Select an operation',
        prefixIcon: Icon(Icons.work_outline),
      ),
      items: _operations.map((operation) {
        return DropdownMenuItem<int>(
          value: operation.id,
          child: Text(operation.operationName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedOperationId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select an operation';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Date *',
        hintText: 'Select date',
        prefixIcon: Icon(Icons.calendar_today),
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      controller: TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(_selectedDate),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
        }
      },
    );
  }

  Widget _buildVehicleTypeDropdown(TransportDetailState state, bool canAddNew) {
    final items = <DropdownMenuItem<int>>[];
    
    // Add existing vehicle types
    for (final vehicleType in state.vehicleTypes) {
      items.add(DropdownMenuItem<int>(
        value: vehicleType.id,
        child: Text(vehicleType.name),
      ));
    }
    
    // Add "Add New" option for managers/admins
    if (canAddNew) {
      items.add(const DropdownMenuItem<int>(
        value: -1,
        child: Text('+ Add New Vehicle Type'),
      ));
    }

    return DropdownButtonFormField<int>(
      value: _selectedVehicleTypeId,
      decoration: const InputDecoration(
        labelText: 'Vehicle Type *',
        hintText: 'Select vehicle type',
        prefixIcon: Icon(Icons.local_shipping),
      ),
      items: items,
      onChanged: (value) async {
        if (value == -1) {
          await _showAddVehicleTypeDialog();
        } else {
          setState(() {
            _selectedVehicleTypeId = value;
          });
        }
      },
      validator: (value) {
        if (value == null || value == -1) {
          return 'Please select a vehicle type';
        }
        return null;
      },
    );
  }

  Widget _buildVehicleNumberField() {
    return TextFormField(
      controller: _vehicleNumberController,
      decoration: const InputDecoration(
        labelText: 'Vehicle Number *',
        hintText: 'e.g., KA-01-1234',
        prefixIcon: Icon(Icons.confirmation_number),
      ),
      textCapitalization: TextCapitalization.characters,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter vehicle number';
        }
        return null;
      },
    );
  }

  Widget _buildContractTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedContractType,
      decoration: const InputDecoration(
        labelText: 'Contract Type *',
        hintText: 'Select contract type',
        prefixIcon: Icon(Icons.description),
      ),
      items: _contractTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(_contractTypeLabels[type] ?? type),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedContractType = value!;
        });
      },
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: const InputDecoration(
        labelText: 'Quantity *',
        hintText: 'Enter quantity',
        prefixIcon: Icon(Icons.scale),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter quantity';
        }
        if (double.tryParse(value.trim()) == null) {
          return 'Please enter valid number';
        }
        return null;
      },
    );
  }

  Widget _buildRateField() {
    return TextFormField(
      controller: _rateController,
      decoration: const InputDecoration(
        labelText: 'Rate *',
        hintText: 'Enter rate',
        prefixIcon: Icon(Icons.currency_rupee),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter rate';
        }
        if (double.tryParse(value.trim()) == null) {
          return 'Please enter valid number';
        }
        return null;
      },
    );
  }

  Widget _buildCalculatedCostCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Calculated Cost',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Text(
            '₹${_calculatedCost.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyDropdown(TransportDetailState state, bool canAddNew) {
    final items = <DropdownMenuItem<int>>[];
    
    // Add existing parties
    for (final party in state.parties) {
      items.add(DropdownMenuItem<int>(
        value: party.id,
        child: Text(party.name),
      ));
    }
    
    // Add "Add New" option for managers/admins
    if (canAddNew) {
      items.add(const DropdownMenuItem<int>(
        value: -1,
        child: Text('+ Add New Party'),
      ));
    }

    return DropdownButtonFormField<int>(
      value: _selectedPartyId,
      decoration: const InputDecoration(
        labelText: 'Party Name *',
        hintText: 'Select party',
        prefixIcon: Icon(Icons.business),
      ),
      items: items,
      onChanged: (value) async {
        if (value == -1) {
          await _showAddPartyDialog();
        } else {
          setState(() {
            _selectedPartyId = value;
          });
        }
      },
      validator: (value) {
        if (value == null || value == -1) {
          return 'Please select a party';
        }
        return null;
      },
    );
  }

  Widget _buildBillNoField() {
    return TextFormField(
      controller: _billNoController,
      decoration: const InputDecoration(
        labelText: 'Bill Number',
        hintText: 'Enter bill number (optional)',
        prefixIcon: Icon(Icons.receipt),
      ),
    );
  }

  Widget _buildRemarksField() {
    return TextFormField(
      controller: _remarksController,
      decoration: const InputDecoration(
        labelText: 'Remarks',
        hintText: 'Enter any additional remarks (optional)',
        prefixIcon: Icon(Icons.note),
      ),
      maxLines: 3,
    );
  }

  Future<void> _showAddVehicleTypeDialog() async {
    final controller = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vehicle Type'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Vehicle Type Name',
            hintText: 'e.g., Truck, Trailer, Container',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final success = await ref.read(transportDetailProvider.notifier)
                    .addVehicleType(controller.text.trim());
                Navigator.of(context).pop(success);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Find and select the new item
      final state = ref.read(transportDetailProvider);
      final newVehicleType = state.vehicleTypes.where(
        (vt) => vt.name.toLowerCase() == controller.text.trim().toLowerCase(),
      ).firstOrNull;
      
      if (newVehicleType != null) {
        setState(() {
          _selectedVehicleTypeId = newVehicleType.id;
        });
      }
    }
  }

  Future<void> _showAddPartyDialog() async {
    final nameController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Party'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Party Name *',
            hintText: 'e.g., XYZ Logistics',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final success = await ref.read(transportDetailProvider.notifier).addParty(
                  name: nameController.text.trim(),
                );
                Navigator.of(context).pop(success);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Find and select the new item
      final state = ref.read(transportDetailProvider);
      final newParty = state.parties.where(
        (p) => p.name.toLowerCase() == nameController.text.trim().toLowerCase(),
      ).firstOrNull;
      
      if (newParty != null) {
        setState(() {
          _selectedPartyId = newParty.id;
        });
      }
    }
  }
} 