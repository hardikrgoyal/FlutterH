import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/vehicle_type_model.dart';
import '../vehicle_providers.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerContactController = TextEditingController();
  final _capacityController = TextEditingController();
  final _makeModelController = TextEditingController();
  final _yearController = TextEditingController();
  final _chassisController = TextEditingController();
  final _engineController = TextEditingController();
  final _remarksController = TextEditingController();

  VehicleType? _selectedVehicleType;
  String _selectedOwnership = 'hired';
  String _selectedStatus = 'active';
  bool _isLoading = false;

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _ownerNameController.dispose();
    _ownerContactController.dispose();
    _capacityController.dispose();
    _makeModelController.dispose();
    _yearController.dispose();
    _chassisController.dispose();
    _engineController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  int? _parseYear(String yearText) {
    try {
      final year = int.parse(yearText);
      // Validate reasonable year range (1900 to current year + 5)
      final currentYear = DateTime.now().year;
      if (year >= 1900 && year <= currentYear + 5) {
        return year;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildVehicleNumberField(),
              const SizedBox(height: 16),
              _buildVehicleTypeField(),
              const SizedBox(height: 16),
              _buildOwnershipField(),
              const SizedBox(height: 16),
              _buildStatusField(),
              const SizedBox(height: 16),
              _buildOwnerNameField(),
              const SizedBox(height: 16),
              _buildOwnerContactField(),
              const SizedBox(height: 16),
              _buildCapacityField(),
              const SizedBox(height: 16),
              _buildMakeModelField(),
              const SizedBox(height: 16),
              _buildYearField(),
              const SizedBox(height: 16),
              _buildChassisField(),
              const SizedBox(height: 16),
              _buildEngineField(),
              const SizedBox(height: 16),
              _buildRemarksField(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleNumberField() {
    return TextFormField(
      controller: _vehicleNumberController,
      decoration: const InputDecoration(
        labelText: 'Vehicle Number *',
        border: OutlineInputBorder(),
        hintText: 'e.g., MH01AB1234',
      ),
      textCapitalization: TextCapitalization.characters,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vehicle number is required';
        }
        return null;
      },
    );
  }

  Widget _buildVehicleTypeField() {
    final vehicleTypesAsync = ref.watch(vehicleTypesProvider);
    
    return vehicleTypesAsync.when(
      data: (vehicleTypes) {
        return DropdownButtonFormField<VehicleType>(
          decoration: const InputDecoration(
            labelText: 'Vehicle Type *',
            border: OutlineInputBorder(),
          ),
          value: _selectedVehicleType,
          items: vehicleTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedVehicleType = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Vehicle type is required';
            }
            return null;
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => Column(
        children: [
          const Icon(Icons.error, color: Colors.red),
          Text('Failed to load vehicle types: $error'),
          ElevatedButton(
            onPressed: () => ref.refresh(vehicleTypesProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnershipField() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Ownership',
        border: OutlineInputBorder(),
      ),
      value: _selectedOwnership,
      items: const [
        DropdownMenuItem(value: 'owned', child: Text('Company Owned')),
        DropdownMenuItem(value: 'hired', child: Text('Hired/Contract')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedOwnership = value!;
        });
      },
    );
  }

  Widget _buildStatusField() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
      value: _selectedStatus,
      items: const [
        DropdownMenuItem(value: 'active', child: Text('Active')),
        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
        DropdownMenuItem(value: 'maintenance', child: Text('Under Maintenance')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedStatus = value!;
        });
      },
    );
  }

  Widget _buildOwnerNameField() {
    return TextFormField(
      controller: _ownerNameController,
      decoration: const InputDecoration(
        labelText: 'Owner Name',
        border: OutlineInputBorder(),
        hintText: 'For hired vehicles',
      ),
    );
  }

  Widget _buildOwnerContactField() {
    return TextFormField(
      controller: _ownerContactController,
      decoration: const InputDecoration(
        labelText: 'Owner Contact',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildCapacityField() {
    return TextFormField(
      controller: _capacityController,
      decoration: const InputDecoration(
        labelText: 'Capacity',
        border: OutlineInputBorder(),
        hintText: 'e.g., 10 MT, 25 CBM',
      ),
    );
  }

  Widget _buildMakeModelField() {
    return TextFormField(
      controller: _makeModelController,
      decoration: const InputDecoration(
        labelText: 'Make & Model',
        border: OutlineInputBorder(),
        hintText: 'e.g., Tata 1109',
      ),
    );
  }

  Widget _buildYearField() {
    return TextFormField(
      controller: _yearController,
      decoration: const InputDecoration(
        labelText: 'Year of Manufacture',
        border: OutlineInputBorder(),
        hintText: 'e.g., 2020',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return null; // Optional field
        }
        final year = _parseYear(value.trim());
        if (year == null) {
          return 'Please enter a valid year (1900 - ${DateTime.now().year + 5})';
        }
        return null;
      },
    );
  }

  Widget _buildChassisField() {
    return TextFormField(
      controller: _chassisController,
      decoration: const InputDecoration(
        labelText: 'Chassis Number',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildEngineField() {
    return TextFormField(
      controller: _engineController,
      decoration: const InputDecoration(
        labelText: 'Engine Number',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildRemarksField() {
    return TextFormField(
      controller: _remarksController,
      decoration: const InputDecoration(
        labelText: 'Remarks',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: AppColors.white)
            : const Text('Add Vehicle'),
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse year safely
      final yearText = _yearController.text.trim();
      final parsedYear = yearText.isNotEmpty ? _parseYear(yearText) : null;
      
      final vehicleData = {
        'vehicle_number': _vehicleNumberController.text.trim(),
        'vehicle_type': _selectedVehicleType!.id,
        'ownership': _selectedOwnership,
        'status': _selectedStatus,
        if (_ownerNameController.text.trim().isNotEmpty)
          'owner_name': _ownerNameController.text.trim(),
        if (_ownerContactController.text.trim().isNotEmpty)
          'owner_contact': _ownerContactController.text.trim(),
        if (_capacityController.text.trim().isNotEmpty)
          'capacity': _capacityController.text.trim(),
        if (_makeModelController.text.trim().isNotEmpty)
          'make_model': _makeModelController.text.trim(),
        if (parsedYear != null)
          'year_of_manufacture': parsedYear,
        if (_chassisController.text.trim().isNotEmpty)
          'chassis_number': _chassisController.text.trim(),
        if (_engineController.text.trim().isNotEmpty)
          'engine_number': _engineController.text.trim(),
        if (_remarksController.text.trim().isNotEmpty)
          'remarks': _remarksController.text.trim(),
      };

      // Debug: Print the data being sent
      print('Creating vehicle with data: $vehicleData');

      await ref.read(vehicleServiceProvider).createVehicle(vehicleData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add vehicle: $e'),
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