import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/models/revenue_stream_model.dart';
import '../../../shared/models/cargo_operation_model.dart';
import '../services/revenue_service.dart';
import '../../auth/auth_service.dart';

class RevenueFormScreen extends ConsumerStatefulWidget {
  final int? streamId;

  const RevenueFormScreen({
    super.key,
    this.streamId,
  });

  @override
  ConsumerState<RevenueFormScreen> createState() => _RevenueFormScreenState();
}

class _RevenueFormScreenState extends ConsumerState<RevenueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();
  final _billNoController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  RevenueStream? _revenueStream;
  List<CargoOperation> _operations = [];
  double _calculatedAmount = 0.0;

  DateTime _selectedDate = DateTime.now();
  int? _selectedOperationId;
  int? _selectedPartyId;
  int? _selectedServiceTypeId;
  int? _selectedUnitTypeId;

  bool get _isEditing => widget.streamId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Add listeners for calculating amount
    _quantityController.addListener(_calculateAmount);
    _rateController.addListener(_calculateAmount);
    
    // Load master data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(revenueStreamProvider.notifier).loadMasterData();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _rateController.dispose();
    _billNoController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load operations
      await ref.read(revenueStreamProvider.notifier).loadOperations();
      final state = ref.read(revenueStreamProvider);
      final operations = state.operations;

      if (!mounted) return;
      setState(() {
        _operations = operations;
      });

      // Load revenue stream if editing
      if (_isEditing) {
        final stream = await ref.read(revenueStreamProvider.notifier).getRevenueStream(widget.streamId!);
        if (!mounted) return;
        
        setState(() {
          _revenueStream = stream;
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
    if (_revenueStream == null) return;

    final formatter = DateFormat('yyyy-MM-dd');
    
    _selectedDate = formatter.parse(_revenueStream!.date);
    _selectedOperationId = _revenueStream!.operation;
    _selectedServiceTypeId = _revenueStream!.serviceType;
    _selectedUnitTypeId = _revenueStream!.unitType;
    
    // Find party ID from name
    final state = ref.read(revenueStreamProvider);
    final party = state.parties.where((p) => p.name == _revenueStream!.party).firstOrNull;
    _selectedPartyId = party?.id;
    
    _quantityController.text = _revenueStream!.quantity;
    _rateController.text = _revenueStream!.rate;
    _billNoController.text = _revenueStream!.billNo ?? '';
    _remarksController.text = _revenueStream!.remarks ?? '';
    
    _calculateAmount();
  }

  void _calculateAmount() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    
    setState(() {
      _calculatedAmount = quantity * rate;
    });
  }

  String _getPartyName() {
    if (_selectedPartyId == null) return '';
    final state = ref.read(revenueStreamProvider);
    final party = state.parties.where((p) => p.id == _selectedPartyId).firstOrNull;
    return party?.name ?? '';
  }

  Future<void> _saveRevenueStream() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final revenueStream = RevenueStream(
        id: _revenueStream?.id ?? 0,
        operation: _selectedOperationId!,
        operationName: _operations.firstWhere((op) => op.id == _selectedOperationId!).operationName,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        party: _getPartyName(),
        serviceType: _selectedServiceTypeId!,
        unitType: _selectedUnitTypeId!,
        quantity: _quantityController.text.trim(),
        rate: _rateController.text.trim(),
        amount: _calculatedAmount.toStringAsFixed(2),
        billNo: _billNoController.text.trim().isEmpty ? null : _billNoController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        createdBy: 1,
        createdByName: ref.read(authStateProvider).user?.username ?? '',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      bool success;
      if (_isEditing) {
        success = await ref.read(revenueStreamProvider.notifier).updateRevenueStream(widget.streamId!, revenueStream);
      } else {
        success = await ref.read(revenueStreamProvider.notifier).createRevenueStream(revenueStream);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Revenue stream ${_isEditing ? 'updated' : 'created'} successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        final error = ref.read(revenueStreamProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to ${_isEditing ? 'update' : 'create'} revenue stream'),
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

  void _showAddPartyDialog() {
    final partyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Party'),
        content: TextField(
          controller: partyController,
          decoration: const InputDecoration(
            labelText: 'Party Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (partyController.text.trim().isNotEmpty) {
                try {
                  final success = await ref.read(revenueStreamProvider.notifier).createParty(partyController.text.trim());
                  if (success && mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Party added successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    // Auto-select the new party
                    final state = ref.read(revenueStreamProvider);
                    final newParty = state.parties.lastOrNull;
                    if (newParty != null) {
                      setState(() {
                        _selectedPartyId = newParty.id;
                      });
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding party: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddServiceTypeDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Service Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Service Type Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Service Type Code',
                border: OutlineInputBorder(),
                helperText: 'e.g., stevedoring, storage, transport',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty && codeController.text.trim().isNotEmpty) {
                try {
                  final success = await ref.read(revenueStreamProvider.notifier).createServiceType(
                    nameController.text.trim(),
                    codeController.text.trim().toLowerCase(),
                  );
                  if (success && mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Service type added successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    // Auto-select the new service type
                    final state = ref.read(revenueStreamProvider);
                    final newServiceType = state.serviceTypes.lastOrNull;
                    if (newServiceType != null) {
                      setState(() {
                        _selectedServiceTypeId = newServiceType.id;
                      });
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding service type: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddUnitTypeDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Unit Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Unit Type Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Unit Type Code',
                border: OutlineInputBorder(),
                helperText: 'e.g., mt, cbm, per_unit',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty && codeController.text.trim().isNotEmpty) {
                try {
                  final success = await ref.read(revenueStreamProvider.notifier).createUnitType(
                    nameController.text.trim(),
                    codeController.text.trim().toLowerCase(),
                  );
                  if (success && mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unit type added successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    // Auto-select the new unit type
                    final state = ref.read(revenueStreamProvider);
                    final newUnitType = state.unitTypes.lastOrNull;
                    if (newUnitType != null) {
                      setState(() {
                        _selectedUnitTypeId = newUnitType.id;
                      });
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding unit type: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  bool _hasPermission() {
    final user = ref.read(authStateProvider).user;
    if (user == null) return false;
    return ['admin', 'manager', 'accountant'].contains(user.role);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission()) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Revenue Stream' : 'Add Revenue Stream'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You do not have permission to manage Revenue Streams.\nContact your administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final state = ref.watch(revenueStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Revenue Stream' : 'Add Revenue Stream'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveRevenueStream,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Basic Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Operation Dropdown
                            DropdownButtonFormField<int>(
                              value: _selectedOperationId,
                              decoration: const InputDecoration(
                                labelText: 'Operation *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.work_outline),
                              ),
                              items: _operations.map((operation) {
                                return DropdownMenuItem(
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
                            ),
                            const SizedBox(height: 16),
                            
                            // Date Picker
                            TextFormField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Date *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                                suffixIcon: Icon(Icons.arrow_drop_down),
                              ),
                              controller: TextEditingController(
                                text: DateFormat('dd MMM yyyy').format(_selectedDate),
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _selectedDate = date;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Party Dropdown with Add New
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: _selectedPartyId,
                                    decoration: const InputDecoration(
                                      labelText: 'Party *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.business),
                                    ),
                                    items: state.parties.map((party) {
                                      return DropdownMenuItem(
                                        value: party.id,
                                        child: Text(party.name),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPartyId = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select a party';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _showAddPartyDialog,
                                  icon: const Icon(Icons.add_circle_outline),
                                  tooltip: 'Add New Party',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Service Details Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service Details',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Service Type Dropdown with Add New
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: _selectedServiceTypeId,
                                        decoration: const InputDecoration(
                                          labelText: 'Service Type *',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.settings),
                                        ),
                                        items: state.serviceTypes.map((serviceType) {
                                          return DropdownMenuItem(
                                            value: serviceType.id,
                                            child: Text(serviceType.name),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedServiceTypeId = value;
                                            });
                                          }
                                        },
                                        validator: (value) => value == null ? 'Required' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: _showAddServiceTypeDialog,
                                      icon: const Icon(Icons.add_circle_outline),
                                      tooltip: 'Add New Service Type',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Unit Type Dropdown with Add New
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: _selectedUnitTypeId,
                                        decoration: const InputDecoration(
                                          labelText: 'Unit Type *',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.straighten),
                                        ),
                                        items: state.unitTypes.map((unitType) {
                                          return DropdownMenuItem(
                                            value: unitType.id,
                                            child: Text(unitType.name),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedUnitTypeId = value;
                                            });
                                          }
                                        },
                                        validator: (value) => value == null ? 'Required' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: _showAddUnitTypeDialog,
                                      icon: const Icon(Icons.add_circle_outline),
                                      tooltip: 'Add New Unit Type',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Pricing Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pricing Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                // Quantity
                                Expanded(
                                  child: TextFormField(
                                    controller: _quantityController,
                                    decoration: const InputDecoration(
                                      labelText: 'Quantity *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.inventory),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Invalid number';
                                      }
                                      if (double.parse(value) <= 0) {
                                        return 'Must be > 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Rate
                                Expanded(
                                  child: TextFormField(
                                    controller: _rateController,
                                    decoration: const InputDecoration(
                                      labelText: 'Rate (₹) *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.currency_rupee),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Invalid number';
                                      }
                                      if (double.parse(value) <= 0) {
                                        return 'Must be > 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Calculated Amount Display
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${_calculatedAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Additional Information Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Additional Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Bill Number
                            TextFormField(
                              controller: _billNoController,
                              decoration: const InputDecoration(
                                labelText: 'Bill Number',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.receipt_long),
                                hintText: 'Enter bill/invoice number',
                              ),
                              textCapitalization: TextCapitalization.characters,
                            ),
                            const SizedBox(height: 16),
                            
                            // Remarks
                            TextFormField(
                              controller: _remarksController,
                              decoration: const InputDecoration(
                                labelText: 'Remarks',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note),
                                hintText: 'Additional notes or comments',
                              ),
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveRevenueStream,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Saving...'),
                                ],
                              )
                            : Text(
                                _isEditing ? 'Update Revenue Stream' : 'Create Revenue Stream',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 