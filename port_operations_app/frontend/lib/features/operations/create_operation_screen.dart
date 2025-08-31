import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../auth/auth_service.dart';
import 'operations_service.dart';

class CreateOperationScreen extends ConsumerStatefulWidget {
  const CreateOperationScreen({super.key});

  @override
  ConsumerState<CreateOperationScreen> createState() => _CreateOperationScreenState();
}

class _CreateOperationScreenState extends ConsumerState<CreateOperationScreen> {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Operation'),
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
                        MdiIcons.shipWheel,
                        size: 32,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Cargo Operation',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Create a new cargo operation entry',
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
                    if (_selectedCargoType == 'Add New...' && (value == null || value.trim().isEmpty)) {
                      return 'Please enter the new cargo type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              _buildTextField(
                controller: _weightController,
                label: 'Weight (MT)',
                hint: 'e.g., 500.50',
                icon: Icons.scale,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Weight is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Party Information Section
              _buildSectionHeader('Party Information', Icons.business),
              const SizedBox(height: 16),

              _buildPartyNameField(),
              const SizedBox(height: 16),

              if (_showNewPartyNameField) ...[
                _buildTextField(
                  controller: _newPartyNameController,
                  label: 'New Party Name',
                  hint: 'Enter new party name',
                  icon: Icons.add,
                  validator: (value) {
                    if (_selectedPartyName == 'Add New...' && (value == null || value.trim().isEmpty)) {
                      return 'Please enter the new party name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),

              // Remarks Section
              _buildSectionHeader('Remarks', Icons.note),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _remarksController,
                label: 'Remarks (Optional)',
                hint: 'Any additional notes...',
                icon: Icons.note,
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
                      onPressed: _isLoading ? null : _createOperation,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Operation'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operation Date',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildCargoTypeField() {
    return DropdownButtonFormField<String>(
      value: _selectedCargoType,
      decoration: const InputDecoration(
        labelText: 'Cargo Type',
        prefixIcon: Icon(Icons.inventory),
        border: OutlineInputBorder(),
      ),
      items: _cargoTypes.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCargoType = value!;
          _showNewCargoTypeField = value == 'Add New...';
          if (!_showNewCargoTypeField) {
            _newCargoTypeController.clear();
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Cargo type is required';
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
      ),
      items: _partyNames.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPartyName = value!;
          _showNewPartyNameField = value == 'Add New...';
          if (!_showNewPartyNameField) {
            _newPartyNameController.clear();
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Party name is required';
        }
        return null;
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createOperation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Determine the final cargo type and party name
      String finalCargoType = _selectedCargoType;
      if (_selectedCargoType == 'Add New...' && _newCargoTypeController.text.trim().isNotEmpty) {
        finalCargoType = _newCargoTypeController.text.trim();
      }

      String finalPartyName = _selectedPartyName;
      if (_selectedPartyName == 'Add New...' && _newPartyNameController.text.trim().isNotEmpty) {
        finalPartyName = _newPartyNameController.text.trim();
      }

      // Convert cargo type to backend format
      String backendCargoType = _cargoTypeMapping[finalCargoType] ?? 
          finalCargoType.toLowerCase().replaceAll(' ', '_');

      final operationData = {
        'operation_name': _operationNameController.text.trim(),
        'date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        'cargo_type': backendCargoType,
        'weight': _weightController.text.trim(),
        'party_name': finalPartyName,
        'remarks': _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      };

      final success = await ref.read(operationsManagementProvider.notifier).createOperation(operationData);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Operation created successfully!'),
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
              content: Text('Failed to create operation: ${error ?? 'Unknown error'}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create operation: ${e.toString()}'),
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