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
  final _packagingController = TextEditingController();
  final _partyNameController = TextEditingController();
  final _remarksController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedCargoType = 'breakbulk';
  String _selectedStatus = 'pending';
  bool _isLoading = false;

  final List<String> _cargoTypes = [
    'breakbulk',
    'container',
    'bulk',
    'project',
    'others',
  ];

  final List<String> _statusTypes = [
    'pending',
    'ongoing',
    'completed',
  ];

  @override
  void dispose() {
    _operationNameController.dispose();
    _weightController.dispose();
    _packagingController.dispose();
    _partyNameController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Operation'),
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
                child: Padding(
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

              _buildDropdownField(
                label: 'Cargo Type',
                value: _selectedCargoType,
                items: _cargoTypes,
                onChanged: (value) {
                  setState(() {
                    _selectedCargoType = value!;
                  });
                },
                icon: Icons.inventory,
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 16),

              _buildTextField(
                controller: _packagingController,
                label: 'Packaging',
                hint: 'e.g., Steel Coils, 20ft Container',
                icon: Icons.inventory_2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Packaging is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Party Information Section
              _buildSectionHeader('Party Information', Icons.business),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _partyNameController,
                label: 'Party Name',
                hint: 'e.g., ABC Steel Industries',
                icon: Icons.business,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Party name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Status & Remarks Section
              _buildSectionHeader('Status & Remarks', Icons.assignment),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Project Status',
                value: _selectedStatus,
                items: _statusTypes,
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
                icon: Icons.assignment_turned_in,
              ),
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

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(_getDisplayName(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  String _getDisplayName(String value) {
    switch (value) {
      case 'breakbulk':
        return 'Breakbulk';
      case 'container':
        return 'Container';
      case 'bulk':
        return 'Bulk';
      case 'project':
        return 'Project Cargo';
      case 'others':
        return 'Others';
      case 'pending':
        return 'Pending';
      case 'ongoing':
        return 'Ongoing';
      case 'completed':
        return 'Completed';
      default:
        return value;
    }
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
      final operationData = {
        'operation_name': _operationNameController.text.trim(),
        'date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        'cargo_type': _selectedCargoType,
        'weight': _weightController.text.trim(),
        'packaging': _packagingController.text.trim(),
        'party_name': _partyNameController.text.trim(),
        'project_status': _selectedStatus,
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