import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../models/equipment_model.dart';
import '../../../shared/models/cargo_operation_model.dart';
import '../../../shared/models/party_master_model.dart';
import '../../../shared/models/vehicle_type_model.dart';
import '../../../shared/models/work_type_model.dart';
import '../services/equipment_service.dart';
import '../../operations/operations_service.dart';
import '../../auth/auth_service.dart';

class EquipmentEditScreen extends ConsumerStatefulWidget {
  final int equipmentId;

  const EquipmentEditScreen({
    super.key,
    required this.equipmentId,
  });

  @override
  ConsumerState<EquipmentEditScreen> createState() => _EquipmentEditScreenState();
}

class _EquipmentEditScreenState extends ConsumerState<EquipmentEditScreen> 
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();
  final _commentsController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  Equipment? _equipment;
  List<CargoOperation> _operations = [];
  List<PartyMaster> _parties = [];
  List<VehicleType> _vehicleTypes = [];
  List<WorkType> _workTypes = [];
  double _calculatedAmount = 0.0;
  
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedInvoiceDate;
  DateTime _selectedStartTime = DateTime.now();
  DateTime? _selectedEndTime;
  int? _selectedOperation;
  int? _selectedParty;
  int? _selectedVehicleType;
  int? _selectedWorkType;
  String? _selectedContractType;
  bool? _invoiceReceived;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _commentsController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Load equipment details
      final equipmentService = ref.read(equipmentServiceProvider);
      final equipment = await equipmentService.getEquipment(widget.equipmentId);
      
      // Load master data
      final operationsService = ref.read(operationsServiceProvider);
      final operations = await operationsService.getOperations();
      final parties = await equipmentService.getParties();
      final vehicleTypes = await equipmentService.getVehicleTypes();
      final workTypes = await equipmentService.getWorkTypes();
      
      if (!mounted) return;
      
      setState(() {
        _equipment = equipment;
        _operations = operations;
        _parties = parties;
        _vehicleTypes = vehicleTypes;
        _workTypes = workTypes;
      });
      
      _populateForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
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
    if (_equipment != null) {
      _vehicleNumberController.text = _equipment!.vehicleNumber;
      _quantityController.text = _equipment!.quantity ?? '';
      _rateController.text = _equipment!.rate ?? '';
      _commentsController.text = _equipment!.comments ?? '';
      _invoiceNumberController.text = _equipment!.invoiceNumber ?? '';
      
      _selectedDate = DateTime.parse(_equipment!.date);
      _selectedStartTime = DateTime.parse(_equipment!.startTime);
      if (_equipment!.endTime != null) {
        _selectedEndTime = DateTime.parse(_equipment!.endTime!);
      }
      if (_equipment!.invoiceDate != null) {
        _selectedInvoiceDate = DateTime.parse(_equipment!.invoiceDate!);
      }
      
      _selectedOperation = _equipment!.operation;
      _selectedParty = _equipment!.party;
      _selectedVehicleType = _equipment!.vehicleType;
      _selectedWorkType = _equipment!.workType;
      _selectedContractType = _equipment!.contractType;
      _invoiceReceived = _equipment!.invoiceReceived;
      
      _calculateAmount();
    }
  }

  void _calculateAmount() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    setState(() {
      _calculatedAmount = quantity * rate;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final user = ref.watch(authStateProvider).user;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Equipment'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton(
              onPressed: _saveEquipment,
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
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              MdiIcons.truck,
                              size: 32,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Equipment Information',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Update equipment details and billing information',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
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
                    
                    // Basic Information Card
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
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Operation Dropdown
                            DropdownButtonFormField<int>(
                              value: _selectedOperation,
                              decoration: const InputDecoration(
                                labelText: 'Operation *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.business),
                              ),
                              items: _operations.map((operation) => DropdownMenuItem(
                                value: operation.id,
                                child: Text(operation.operationName),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedOperation = value;
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
                              ),
                              controller: TextEditingController(
                                text: DateFormat('MMM dd, yyyy').format(_selectedDate),
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _selectedDate = date;
                                  });
                                }
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Vehicle Type Dropdown
                            DropdownButtonFormField<int>(
                              value: _selectedVehicleType,
                              decoration: const InputDecoration(
                                labelText: 'Vehicle Type *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.local_shipping),
                              ),
                              items: _vehicleTypes.map((type) => DropdownMenuItem(
                                value: type.id,
                                child: Text(type.name),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedVehicleType = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a vehicle type';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Vehicle Number
                            TextFormField(
                              controller: _vehicleNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Vehicle Number *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.confirmation_number),
                              ),
                              validator: (value) {
                                if (value?.trim().isEmpty == true) {
                                  return 'Please enter vehicle number';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Work Type Dropdown
                            DropdownButtonFormField<int>(
                              value: _selectedWorkType,
                              decoration: const InputDecoration(
                                labelText: 'Work Type *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.build),
                              ),
                              items: _workTypes.map((type) => DropdownMenuItem(
                                value: type.id,
                                child: Text(type.name),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedWorkType = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a work type';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Party Dropdown
                            DropdownButtonFormField<int>(
                              value: _selectedParty,
                              decoration: const InputDecoration(
                                labelText: 'Party *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              items: _parties.map((party) => DropdownMenuItem(
                                value: party.id,
                                child: Text(party.name),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedParty = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a party';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Contract Type Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedContractType,
                              decoration: const InputDecoration(
                                labelText: 'Contract Type *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.assignment),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                                DropdownMenuItem(value: 'shift', child: Text('Shift')),
                                DropdownMenuItem(value: 'tonnes', child: Text('Tonnes')),
                                DropdownMenuItem(value: 'hours', child: Text('Hours')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedContractType = value;
                                });
                              },
                              validator: (value) {
                                if (value?.trim().isEmpty == true) {
                                  return 'Please select contract type';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Time Tracking Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time Tracking',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Start Time
                            TextFormField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Start Time *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.play_arrow),
                              ),
                              controller: TextEditingController(
                                text: DateFormat('MMM dd, yyyy • HH:mm').format(_selectedStartTime),
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedStartTime,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
                                );
                                if (date != null) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(_selectedStartTime),
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _selectedStartTime = DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        time.hour,
                                        time.minute,
                                      );
                                    });
                                  }
                                }
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // End Time
                            TextFormField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'End Time',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.stop),
                                helperText: 'Leave empty if equipment is still running',
                              ),
                              controller: TextEditingController(
                                text: _selectedEndTime != null 
                                    ? DateFormat('MMM dd, yyyy • HH:mm').format(_selectedEndTime!)
                                    : '',
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedEndTime ?? DateTime.now(),
                                  firstDate: _selectedStartTime,
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
                                );
                                if (date != null) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _selectedEndTime != null 
                                        ? TimeOfDay.fromDateTime(_selectedEndTime!)
                                        : TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _selectedEndTime = DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        time.hour,
                                        time.minute,
                                      );
                                    });
                                  }
                                }
                              },
                            ),
                            
                            // Clear End Time Button
                            if (_selectedEndTime != null) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedEndTime = null;
                                  });
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear End Time'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    // Cost Information Card (only for admin/manager)
                    if (user.canAccessCostDetails) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cost Information',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Quantity
                              TextFormField(
                                controller: _quantityController,
                                decoration: InputDecoration(
                                  labelText: 'Quantity',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.scale),
                                  helperText: _getQuantityHelperText(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _calculateAmount(),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Rate
                              TextFormField(
                                controller: _rateController,
                                decoration: const InputDecoration(
                                  labelText: 'Rate (₹)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _calculateAmount(),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Calculated Amount Display
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.grey50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Calculated Amount:',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      '₹${NumberFormat('#,##0.00').format(_calculatedAmount)}',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    ],
                    
                    // Invoice Information Card (only for admin/manager)
                    if (user.canAccessCostDetails) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Invoice Information',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Invoice Number
                              TextFormField(
                                controller: _invoiceNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Invoice Number',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.confirmation_number),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Invoice Date
                              TextFormField(
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Invoice Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                controller: TextEditingController(
                                  text: _selectedInvoiceDate != null 
                                      ? DateFormat('MMM dd, yyyy').format(_selectedInvoiceDate!)
                                      : '',
                                ),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedInvoiceDate ?? DateTime.now(),
                                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                    lastDate: DateTime.now().add(const Duration(days: 30)),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _selectedInvoiceDate = date;
                                    });
                                  }
                                },
                              ),
                              
                              // Clear Invoice Date Button
                              if (_selectedInvoiceDate != null) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedInvoiceDate = null;
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Clear Invoice Date'),
                                ),
                              ],
                              
                              const SizedBox(height: 16),
                              
                              // Invoice Status
                              DropdownButtonFormField<bool?>(
                                value: _invoiceReceived,
                                decoration: const InputDecoration(
                                  labelText: 'Invoice Status',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.receipt),
                                ),
                                items: const [
                                  DropdownMenuItem(value: null, child: Text('Pending')),
                                  DropdownMenuItem(value: true, child: Text('Received')),
                                  DropdownMenuItem(value: false, child: Text('Not Applicable')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _invoiceReceived = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Comments Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Comments',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _commentsController,
                              decoration: const InputDecoration(
                                labelText: 'Comments',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.comment),
                              ),
                              maxLines: 3,
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
                        onPressed: _isSaving ? null : _saveEquipment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
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
                            : const Text(
                                'Save Equipment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  String? _getQuantityHelperText() {
    switch (_selectedContractType?.toLowerCase()) {
      case 'hours':
        return 'Enter hours worked';
      case 'shift':
        return 'Enter number of shifts';
      case 'tonnes':
        return 'Enter tonnage moved';
      case 'fixed':
        return 'Fixed rate (usually 1)';
      default:
        return 'Enter quantity';
    }
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final equipmentService = ref.read(equipmentServiceProvider);
      
      final updateData = {
        'operation': _selectedOperation,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'vehicle_type': _selectedVehicleType,
        'vehicle_number': _vehicleNumberController.text.trim(),
        'work_type': _selectedWorkType,
        'party': _selectedParty,
        'contract_type': _selectedContractType,
        'start_time': _selectedStartTime.toIso8601String(),
        'end_time': _selectedEndTime?.toIso8601String(),
        'comments': _commentsController.text.trim().isNotEmpty 
            ? _commentsController.text.trim() 
            : null,
      };

      // Add cost information if user can access it
      final user = ref.read(authStateProvider).user!;
      if (user.canAccessCostDetails) {
        if (_quantityController.text.isNotEmpty) {
          updateData['quantity'] = _quantityController.text;
        }
        if (_rateController.text.isNotEmpty) {
          updateData['rate'] = _rateController.text;
        }
        if (_invoiceNumberController.text.isNotEmpty) {
          updateData['invoice_number'] = _invoiceNumberController.text.trim();
        }
        if (_selectedInvoiceDate != null) {
          updateData['invoice_date'] = DateFormat('yyyy-MM-dd').format(_selectedInvoiceDate!);
        }
        updateData['invoice_received'] = _invoiceReceived;
      }

      await equipmentService.updateEquipment(widget.equipmentId, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(); // Go back to detail screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update equipment: $e'),
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
} 