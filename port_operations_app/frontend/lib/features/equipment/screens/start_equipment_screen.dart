import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/equipment_service.dart';
import '../../auth/auth_service.dart';
import 'package:go_router/go_router.dart';

class StartEquipmentScreen extends ConsumerStatefulWidget {
  const StartEquipmentScreen({super.key});

  @override
  ConsumerState<StartEquipmentScreen> createState() => _StartEquipmentScreenState();
}

class _StartEquipmentScreenState extends ConsumerState<StartEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  
  int? _selectedOperationId;
  DateTime _selectedDate = DateTime.now();
  int? _selectedVehicleTypeId;
  int? _selectedWorkTypeId;
  int? _selectedPartyId;
  String _selectedContractType = 'hours';
  DateTime _selectedStartTime = DateTime.now();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load master data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(equipmentManagementProvider.notifier).loadMasterData();
    });
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equipmentState = ref.watch(equipmentManagementProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    
    // Check if user can add new items (managers and admins)
    final canAddNew = user?.role == 'manager' || user?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Equipment'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          equipmentState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error display
                        if (equipmentState.error != null) ...[
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
                                    equipmentState.error!,
                                    style: TextStyle(color: Colors.red.shade600),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => ref.read(equipmentManagementProvider.notifier).clearError(),
                                  icon: const Icon(Icons.close),
                                  iconSize: 20,
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Operation Name
                        _buildSectionHeader('Operation Details'),
                        _buildOperationDropdown(equipmentState),
                        const SizedBox(height: 16),

                        // Date
                        _buildDateField(),
                        const SizedBox(height: 24),

                        // Vehicle Details
                        _buildSectionHeader('Vehicle Details'),
                        _buildVehicleTypeDropdown(equipmentState, canAddNew),
                        const SizedBox(height: 16),
                        
                        _buildVehicleNumberField(),
                        const SizedBox(height: 24),

                        // Work Details
                        _buildSectionHeader('Work Details'),
                        _buildWorkTypeDropdown(equipmentState, canAddNew),
                        const SizedBox(height: 16),
                        
                        _buildPartyDropdown(equipmentState, canAddNew),
                        const SizedBox(height: 16),
                        
                        _buildContractTypeDropdown(),
                        const SizedBox(height: 24),

                        // Time Details
                        _buildSectionHeader('Time Details'),
                        _buildStartTimeField(),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _canSubmit() ? _submitForm : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Start Equipment',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          if (_isLoading)
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildOperationDropdown(EquipmentManagementState state) {
    return DropdownButtonFormField<int>(
      value: _selectedOperationId,
      decoration: const InputDecoration(
        labelText: 'Operation Name *',
        hintText: 'Select operation',
        prefixIcon: Icon(Icons.work_outline),
      ),
      items: state.runningOperations.map((operation) {
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
          firstDate: DateTime.now().subtract(const Duration(days: 7)),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
        }
      },
    );
  }

  Widget _buildVehicleTypeDropdown(EquipmentManagementState state, bool canAddNew) {
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
        prefixIcon: Icon(Icons.directions_car),
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
        hintText: 'Enter vehicle number (e.g., KA-01-1234)',
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

  Widget _buildWorkTypeDropdown(EquipmentManagementState state, bool canAddNew) {
    final items = <DropdownMenuItem<int>>[];
    
    // Add existing work types
    for (final workType in state.workTypes) {
      items.add(DropdownMenuItem<int>(
        value: workType.id,
        child: Text(workType.name),
      ));
    }
    
    // Add "Add New" option for managers/admins
    if (canAddNew) {
      items.add(const DropdownMenuItem<int>(
        value: -1,
        child: Text('+ Add New Work Type'),
      ));
    }

    return DropdownButtonFormField<int>(
      value: _selectedWorkTypeId,
      decoration: const InputDecoration(
        labelText: 'Work Type *',
        hintText: 'Select work type',
        prefixIcon: Icon(Icons.build),
      ),
      items: items,
      onChanged: (value) async {
        if (value == -1) {
          await _showAddWorkTypeDialog();
        } else {
          setState(() {
            _selectedWorkTypeId = value;
          });
        }
      },
      validator: (value) {
        if (value == null || value == -1) {
          return 'Please select a work type';
        }
        return null;
      },
    );
  }

  Widget _buildPartyDropdown(EquipmentManagementState state, bool canAddNew) {
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

  Widget _buildContractTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedContractType,
      decoration: const InputDecoration(
        labelText: 'Contract Type *',
        hintText: 'Select contract type',
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
          _selectedContractType = value!;
        });
      },
    );
  }

  Widget _buildStartTimeField() {
    return TextFormField(
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Start Time *',
        hintText: 'Select start time',
        prefixIcon: Icon(Icons.access_time),
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      controller: TextEditingController(
        text: DateFormat('dd/MM/yyyy HH:mm').format(_selectedStartTime),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedStartTime,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 1)),
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
    );
  }

  bool _canSubmit() {
    return _selectedOperationId != null &&
           _selectedVehicleTypeId != null &&
           _selectedWorkTypeId != null &&
           _selectedPartyId != null &&
           _vehicleNumberController.text.trim().isNotEmpty;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref.read(equipmentManagementProvider.notifier).startEquipment(
        operationId: _selectedOperationId!,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        vehicleTypeId: _selectedVehicleTypeId!,
        vehicleNumber: _vehicleNumberController.text.trim(),
        workTypeId: _selectedWorkTypeId!,
        partyId: _selectedPartyId!,
        contractType: _selectedContractType,
        startTime: _selectedStartTime,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment started successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to previous screen
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
            hintText: 'e.g., Hydra, Forklift',
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
                final success = await ref.read(equipmentManagementProvider.notifier)
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
      final state = ref.read(equipmentManagementProvider);
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

  Future<void> _showAddWorkTypeDialog() async {
    final controller = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Work Type'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Work Type Name',
            hintText: 'e.g., Loading, Unloading',
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
                final success = await ref.read(equipmentManagementProvider.notifier)
                    .addWorkType(controller.text.trim());
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
      final state = ref.read(equipmentManagementProvider);
      final newWorkType = state.workTypes.where(
        (wt) => wt.name.toLowerCase() == controller.text.trim().toLowerCase(),
      ).firstOrNull;
      
      if (newWorkType != null) {
        setState(() {
          _selectedWorkTypeId = newWorkType.id;
        });
      }
    }
  }

  Future<void> _showAddPartyDialog() async {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final phoneController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Party'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Party Name *',
                hintText: 'e.g., XYZ Equipment',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contactController,
              decoration: const InputDecoration(
                labelText: 'Contact Person',
                hintText: 'e.g., John Doe',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'e.g., +91-9876543210',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final success = await ref.read(equipmentManagementProvider.notifier).addParty(
                  name: nameController.text.trim(),
                  contactPerson: contactController.text.trim().isNotEmpty 
                      ? contactController.text.trim() 
                      : null,
                  phoneNumber: phoneController.text.trim().isNotEmpty 
                      ? phoneController.text.trim() 
                      : null,
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
      final state = ref.read(equipmentManagementProvider);
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