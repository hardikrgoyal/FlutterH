import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/cargo_operation_model.dart';
import '../auth/auth_service.dart';
import 'operations_service.dart';

class EditOperationScreen extends ConsumerStatefulWidget {
  final int operationId;
  
  const EditOperationScreen({
    super.key,
    required this.operationId,
  });

  @override
  ConsumerState<EditOperationScreen> createState() => _EditOperationScreenState();
}

class _EditOperationScreenState extends ConsumerState<EditOperationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _operationNameController = TextEditingController();
  final _weightController = TextEditingController();
  final _remarksController = TextEditingController();
  final _newCargoTypeController = TextEditingController();
  final _newPartyNameController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedCargoType = 'Paper Bales';
  String _selectedPartyName = 'Arya Translogistics';
  bool _isLoading = false;
  bool _showNewCargoTypeField = false;
  bool _showNewPartyNameField = false;
  CargoOperation? _operation;

  final List<String> _cargoTypes = [
    'Paper Bales',
    'Raw Salt',
    'Coal',
    'Silica',
    'Add New...',
  ];

  final List<String> _partyNames = [
    'Arya Translogistics',
    'Jeel Kandla',
    'Add New...',
  ];

  // Mapping from display names to backend keys
  final Map<String, String> _cargoTypeMapping = {
    'Paper Bales': 'paper_bales',
    'Raw Salt': 'raw_salt',
    'Coal': 'coal',
    'Silica': 'silica',
  };

  // Reverse mapping from backend keys to display names
  final Map<String, String> _cargoTypeReverseMapping = {
    'paper_bales': 'Paper Bales',
    'raw_salt': 'Raw Salt',
    'coal': 'Coal',
    'silica': 'Silica',
  };

  @override
  void initState() {
    super.initState();
    _loadOperation();
  }

  Future<void> _loadOperation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final operations = ref.read(operationsManagementProvider).operations;
      final operation = operations.firstWhere((op) => op.id == widget.operationId);
      
      setState(() {
        _operation = operation;
        _operationNameController.text = operation.operationName;
        _weightController.text = operation.weight;
        _remarksController.text = operation.remarks ?? '';
        _selectedDate = DateTime.parse(operation.date);
        
        // Set cargo type
        final displayCargoType = _cargoTypeReverseMapping[operation.cargoType];
        if (displayCargoType != null) {
          _selectedCargoType = displayCargoType;
        } else {
          _selectedCargoType = operation.displayCargoType;
          _showNewCargoTypeField = true;
          _newCargoTypeController.text = operation.displayCargoType;
        }
        
        // Set party name
        if (_partyNames.contains(operation.partyName)) {
          _selectedPartyName = operation.partyName;
        } else {
          _selectedPartyName = 'Add New...';
          _showNewPartyNameField = true;
          _newPartyNameController.text = operation.partyName;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading operation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        context.go('/operations');
      }
    }
  }

  @override
  void dispose() {
    _operationNameController.dispose();
    _weightController.dispose();
    _remarksController.dispose();
    _newCargoTypeController.dispose();
    _newPartyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _operation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Operation'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Operation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/operations'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        MdiIcons.pencil,
                        size: 32,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Cargo Operation',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Modify cargo operation details',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Operation Details Section
              _buildSectionHeader('Operation Details', MdiIcons.informationOutline),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _operationNameController,
                label: 'Operation Name',
                hint: 'e.g., BREAKBULK-001',
                icon: Icons.business,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Operation name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildDateField(),
              const SizedBox(height: 16),

              _buildCargoTypeField(),
              const SizedBox(height: 16),

              if (_showNewCargoTypeField) ...[
                _buildTextField(
                  controller: _newCargoTypeController,
                  label: 'New Cargo Type',
                  hint: 'Enter new cargo type',
                  icon: Icons.add,
                  validator: (value) {
                    if (_showNewCargoTypeField && (value == null || value.trim().isEmpty)) {
                      return 'New cargo type is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Cargo Information Section
              _buildSectionHeader('Cargo Information', MdiIcons.package),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _weightController,
                label: 'Weight (MT)',
                hint: 'e.g., 1500.50',
                icon: Icons.scale,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Weight is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Weight must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildPartyNameField(),
              const SizedBox(height: 16),

              if (_showNewPartyNameField) ...[
                _buildTextField(
                  controller: _newPartyNameController,
                  label: 'New Party Name',
                  hint: 'Enter party name',
                  icon: Icons.business,
                  validator: (value) {
                    if (_showNewPartyNameField && (value == null || value.trim().isEmpty)) {
                      return 'Party name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Additional Information Section
              _buildSectionHeader('Additional Information', MdiIcons.noteTextOutline),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _remarksController,
                label: 'Remarks (Optional)',
                hint: 'Any additional notes about the operation',
                icon: Icons.note_add,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => context.go('/operations'),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateOperation,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update Operation'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null && picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Operation Date',
          hintText: 'Select date',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildCargoTypeField() {
    return DropdownButtonFormField<String>(
      value: _selectedCargoType,
      decoration: InputDecoration(
        labelText: 'Cargo Type',
        prefixIcon: Icon(MdiIcons.package),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _cargoTypes.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCargoType = newValue!;
          _showNewCargoTypeField = newValue == 'Add New...';
          if (!_showNewCargoTypeField) {
            _newCargoTypeController.clear();
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a cargo type';
        }
        return null;
      },
    );
  }

  Widget _buildPartyNameField() {
    return DropdownButtonFormField<String>(
      value: _selectedPartyName,
      decoration: const InputDecoration(
        labelText: 'Party Name',
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _partyNames.map((String name) {
        return DropdownMenuItem<String>(
          value: name,
          child: Text(name),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedPartyName = newValue!;
          _showNewPartyNameField = newValue == 'Add New...';
          if (!_showNewPartyNameField) {
            _newPartyNameController.clear();
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a party name';
        }
        return null;
      },
    );
  }

  Future<void> _updateOperation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check permissions
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user == null || !user.canEditOperations) {
             ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: const Text('You do not have permission to edit operations'),
           backgroundColor: Colors.red,
         ),
       );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get final cargo type
      String finalCargoType;
      if (_showNewCargoTypeField && _newCargoTypeController.text.isNotEmpty) {
        finalCargoType = _newCargoTypeController.text.toLowerCase().replaceAll(' ', '_');
      } else {
        finalCargoType = _cargoTypeMapping[_selectedCargoType] ?? _selectedCargoType.toLowerCase().replaceAll(' ', '_');
      }

      // Get final party name
      String finalPartyName;
      if (_showNewPartyNameField && _newPartyNameController.text.isNotEmpty) {
        finalPartyName = _newPartyNameController.text;
      } else {
        finalPartyName = _selectedPartyName;
      }

      final operationData = {
        'operation_name': _operationNameController.text.trim(),
        'date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        'cargo_type': finalCargoType,
        'weight': _weightController.text.trim(),
        'party_name': finalPartyName,
        'remarks': _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      };

      final success = await ref.read(operationsManagementProvider.notifier).updateOperation(
        widget.operationId,
        operationData,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Operation updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/operations');
        }
      } else {
        if (mounted) {
          final error = ref.read(operationsManagementProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to update operation'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating operation: $e'),
            backgroundColor: AppColors.error,
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