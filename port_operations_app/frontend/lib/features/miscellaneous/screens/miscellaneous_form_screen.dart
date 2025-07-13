import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/models/miscellaneous_cost_model.dart';
import '../../../shared/models/cargo_operation_model.dart';
import '../services/miscellaneous_service.dart';
import '../../auth/auth_service.dart';

class MiscellaneousFormScreen extends ConsumerStatefulWidget {
  final int? costId;

  const MiscellaneousFormScreen({
    super.key,
    this.costId,
  });

  @override
  ConsumerState<MiscellaneousFormScreen> createState() => _MiscellaneousFormScreenState();
}

class _MiscellaneousFormScreenState extends ConsumerState<MiscellaneousFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();
  final _billNoController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  MiscellaneousCost? _miscCost;
  List<CargoOperation> _operations = [];
  double _calculatedAmount = 0.0;

  DateTime _selectedDate = DateTime.now();
  int? _selectedOperationId;
  int? _selectedPartyId;
  String _selectedCostType = 'material';

  bool get _isEditing => widget.costId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Add listeners for calculating amount
    _quantityController.addListener(_calculateAmount);
    _rateController.addListener(_calculateAmount);
    
    // Load master data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miscellaneousCostProvider.notifier).loadMasterData();
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
      await ref.read(miscellaneousCostProvider.notifier).loadOperations();
      final state = ref.read(miscellaneousCostProvider);
      final operations = state.operations;

      if (!mounted) return;
      setState(() {
        _operations = operations;
      });

      // Load miscellaneous cost if editing
      if (_isEditing) {
        final cost = await ref.read(miscellaneousCostProvider.notifier).getMiscellaneousCost(widget.costId!);
        if (!mounted) return;
        
        setState(() {
          _miscCost = cost;
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
    if (_miscCost == null) return;

    final formatter = DateFormat('yyyy-MM-dd');
    
    _selectedDate = formatter.parse(_miscCost!.date);
    _selectedOperationId = _miscCost!.operation;
    _selectedCostType = _miscCost!.costType;
    
    // Find party ID from name
    final state = ref.read(miscellaneousCostProvider);
    final party = state.parties.where((p) => p.name == _miscCost!.party).firstOrNull;
    _selectedPartyId = party?.id;
    
    _quantityController.text = _miscCost!.quantity;
    _rateController.text = _miscCost!.rate;
    _billNoController.text = _miscCost!.billNo ?? '';
    _remarksController.text = _miscCost!.remarks ?? '';
    
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
    final state = ref.read(miscellaneousCostProvider);
    final party = state.parties.where((p) => p.id == _selectedPartyId).firstOrNull;
    return party?.name ?? '';
  }

  Future<void> _saveMiscellaneousCost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final miscellaneousCost = MiscellaneousCost(
        id: _miscCost?.id ?? 0,
        operation: _selectedOperationId!,
        operationName: _operations.firstWhere((op) => op.id == _selectedOperationId!).operationName,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        party: _getPartyName(),
        costType: _selectedCostType,
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
        success = await ref.read(miscellaneousCostProvider.notifier).updateMiscellaneousCost(widget.costId!, miscellaneousCost);
      } else {
        success = await ref.read(miscellaneousCostProvider.notifier).createMiscellaneousCost(miscellaneousCost);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Miscellaneous cost ${_isEditing ? 'updated' : 'created'} successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        final error = ref.read(miscellaneousCostProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to ${_isEditing ? 'update' : 'create'} miscellaneous cost'),
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
    final miscState = ref.watch(miscellaneousCostProvider);

    // Check if user can add new items (managers and admins)
    final canAddNew = user?.role == 'manager' || user?.role == 'admin';

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Miscellaneous Cost' : 'Add Miscellaneous Cost'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton(
              onPressed: _saveMiscellaneousCost,
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
                        if (miscState.error != null) ...[
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
                                    miscState.error!,
                                    style: TextStyle(color: Colors.red.shade600),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => ref.read(miscellaneousCostProvider.notifier).clearError(),
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

                        // Cost Details Section
                        _buildSectionHeader('Cost Details', Icons.receipt_long),
                        const SizedBox(height: 12),
                        _buildPartyDropdown(miscState, canAddNew),
                        const SizedBox(height: 16),
                        _buildCostTypeDropdown(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildQuantityField()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildRateField()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCalculatedAmountCard(),
                        const SizedBox(height: 24),

                        // Additional Information Section
                        _buildSectionHeader('Additional Information', Icons.note),
                        const SizedBox(height: 12),
                        _buildBillNoField(),
                        const SizedBox(height: 16),
                        _buildRemarksField(),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveMiscellaneousCost,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator()
                                : Text(
                                    _isEditing ? 'Update Miscellaneous Cost' : 'Create Miscellaneous Cost',
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

  Widget _buildPartyDropdown(MiscellaneousCostState state, bool canAddNew) {
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

  Widget _buildCostTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCostType,
      decoration: const InputDecoration(
        labelText: 'Cost Type *',
        hintText: 'Select cost type',
        prefixIcon: Icon(Icons.category),
      ),
      items: MiscellaneousCost.costTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(MiscellaneousCost.costTypeLabels[type] ?? type),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCostType = value!;
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

  Widget _buildCalculatedAmountCard() {
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
                'Calculated Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Text(
            '₹${_calculatedAmount.toStringAsFixed(2)}',
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
                final success = await ref.read(miscellaneousCostProvider.notifier).addParty(
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
      final state = ref.read(miscellaneousCostProvider);
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