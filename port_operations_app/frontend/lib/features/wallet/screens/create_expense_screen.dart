import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../wallet_provider.dart';
import '../../auth/auth_service.dart';
import '../../../shared/widgets/vehicle_search_dropdown.dart';
import '../../../shared/models/vehicle_model.dart';
import '../../../features/maintenance/services/list_management_service.dart';

class CreateExpenseScreen extends ConsumerStatefulWidget {
  const CreateExpenseScreen({super.key});

  @override
  ConsumerState<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends ConsumerState<CreateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cisfAmountController = TextEditingController(text: '50.00');
  final _kptAmountController = TextEditingController(text: '50.00');
  final _customsAmountController = TextEditingController(text: '50.00');
  final _roadTaxDaysController = TextEditingController(text: '0');
  final _otherChargesController = TextEditingController(text: '0.00');
  final _newVehicleTypeController = TextEditingController();

  String _selectedVehicleType = '';
  String _selectedGate = 'north_gate';
  String _selectedInOut = 'In';
  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = false;
  bool _showAddNewVehicleType = false;
  
  // Vehicle selection state
  String? _selectedVehicleNumber;
  String? _customVehicleNumber;
  Vehicle? _selectedVehicleObject;
  
  XFile? _selectedPhoto;
  final ImagePicker _imagePicker = ImagePicker();

  List<String> _vehicleTypes = [];

  final List<Map<String, String>> _gateOptions = [
    {'value': 'north_gate', 'label': 'North Gate'},
    {'value': 'bandar_area', 'label': 'Bandar Area'},
    {'value': 'west_gate_1', 'label': 'West Gate 1'},
    {'value': 'west_gate_2', 'label': 'West Gate 2'},
    {'value': 'west_gate_3', 'label': 'West Gate 3'},
    {'value': 'cj_13', 'label': 'CJ 13'},
  ];

  final List<String> _inOutOptions = ['In', 'Out'];

  @override
  void initState() {
    super.initState();
    // Add listeners for real-time total calculation
    _cisfAmountController.addListener(_updateTotal);
    _kptAmountController.addListener(_updateTotal);
    _customsAmountController.addListener(_updateTotal);
    _roadTaxDaysController.addListener(_updateTotal);
    _otherChargesController.addListener(_updateTotal);
    _loadVehicleTypes();
  }

  Future<void> _loadVehicleTypes() async {
    try {
      final listData = await ref.read(listManagementProvider.notifier).getListData('equipment_vehicle_types');
      if (listData != null && mounted) {
        setState(() {
          _vehicleTypes = listData.items.map((item) => item.name).toList();
          // Set default vehicle type if list is not empty
          if (_vehicleTypes.isNotEmpty && !_vehicleTypes.contains(_selectedVehicleType)) {
            _selectedVehicleType = _vehicleTypes.first;
          }
        });
      }
    } catch (e) {
      // Fallback to hardcoded types if master data fails
      if (mounted) {
        setState(() {
          _vehicleTypes = ['Loader', 'Excavator', 'Truck/Trailer'];
          _selectedVehicleType = _vehicleTypes.first;
        });
      }
    }
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _descriptionController.dispose();
    _cisfAmountController.dispose();
    _kptAmountController.dispose();
    _customsAmountController.dispose();
    _roadTaxDaysController.dispose();
    _otherChargesController.dispose();
    _newVehicleTypeController.dispose();
    super.dispose();
  }

  void _updateTotal() {
    setState(() {
      // This will trigger a rebuild and update the total display
    });
  }

  bool get _canAddVehicleType {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    return user != null && (user.isAdmin || user.isManager);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Port Expense'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Vehicle Information'),
              VehicleSearchDropdown(
                selectedVehicleNumber: _selectedVehicleNumber,
                customVehicleNumber: _customVehicleNumber,
                onVehicleSelected: (vehicleNumber) {
                  setState(() {
                    _selectedVehicleNumber = vehicleNumber;
                    if (vehicleNumber != 'others') {
                      _vehicleNumberController.text = vehicleNumber ?? '';
                      _customVehicleNumber = null;
                    } else {
                      // Reset to default vehicle type when "Others" is selected
                      _selectedVehicleType = _vehicleTypes.isNotEmpty ? _vehicleTypes.first : '';
                    }
                  });
                },
                onVehicleObjectSelected: (vehicle) {
                  setState(() {
                    _selectedVehicleObject = vehicle;
                    if (vehicle != null) {
                      // Add the vehicle type to the list if it doesn't exist
                      if (!_vehicleTypes.contains(vehicle.vehicleTypeName)) {
                        _vehicleTypes.add(vehicle.vehicleTypeName);
                      }
                      // Auto-set vehicle type when a vehicle is selected
                      _selectedVehicleType = vehicle.vehicleTypeName;
                    }
                  });
                },
                onCustomVehicleChanged: (customVehicle) {
                  setState(() {
                    _customVehicleNumber = customVehicle;
                    _vehicleNumberController.text = customVehicle ?? '';
                  });
                },
                labelText: 'Vehicle Number',
                hintText: 'Search and select vehicle',
                showOthersOption: true,
              ),
              const SizedBox(height: 16),
              _buildVehicleTypeDropdown(),
              const SizedBox(height: 16),
              _buildGateDropdown(),
              const SizedBox(height: 16),
              _buildInOutDropdown(),
              const SizedBox(height: 16),
              _buildDateTimePicker(),
              const SizedBox(height: 24),

              _buildSectionHeader('Expense Details'),
              _buildAmountField(
                controller: _cisfAmountController,
                label: 'CISF Amount',
                hint: '50.00',
              ),
              const SizedBox(height: 16),
              _buildAmountField(
                controller: _kptAmountController,
                label: 'KPT Amount',
                hint: '50.00',
              ),
              const SizedBox(height: 16),
              _buildAmountField(
                controller: _customsAmountController,
                label: 'Customs Amount',
                hint: '50.00',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _roadTaxDaysController,
                label: 'Road Tax Days',
                hint: '0',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Road tax days is required';
                  if (int.tryParse(value!) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildAmountField(
                controller: _otherChargesController,
                label: 'Other Charges',
                hint: '0.00',
              ),
              const SizedBox(height: 16),
              _buildPhotoUploadSection(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Enter expense description',
                maxLines: 3,
                validator: (value) => value?.isEmpty == true ? 'Description is required' : null,
              ),
              const SizedBox(height: 24),

              _buildTotalDisplay(),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Expense',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleTypeDropdown() {
    bool isAutoFilled = _selectedVehicleObject != null && _selectedVehicleNumber != 'others';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _vehicleTypes.contains(_selectedVehicleType) ? _selectedVehicleType : null,
          decoration: InputDecoration(
            labelText: isAutoFilled ? 'Vehicle Type (Auto-filled)' : 'Vehicle Type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            // Add visual indication when auto-filled
            suffixIcon: isAutoFilled 
                ? Icon(Icons.check_circle, color: AppColors.success, size: 20)
                : null,
          ),
          items: [
            ..._vehicleTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }),
            if (_canAddVehicleType)
              const DropdownMenuItem(
                value: 'add_new',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Add New Vehicle Type', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
          ],
          onChanged: isAutoFilled ? null : (value) {
            if (value == 'add_new') {
              setState(() {
                _showAddNewVehicleType = true;
              });
            } else {
              setState(() {
                _selectedVehicleType = value!;
                _showAddNewVehicleType = false;
              });
            }
          },
          validator: (value) => value?.isEmpty == true || value == 'add_new' ? 'Vehicle type is required' : null,
        ),
        if (isAutoFilled) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                                child: Text(
                   'Vehicle type automatically set from "${_selectedVehicleObject?.vehicleNumber}". Select "Others" to choose manually.',
                   style: TextStyle(
                     fontSize: 12,
                     color: Colors.grey.shade600,
                   ),
                 ),
              ),
            ],
          ),
        ],
        if (_showAddNewVehicleType && _canAddVehicleType) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _newVehicleTypeController,
                  decoration: InputDecoration(
                    labelText: 'New Vehicle Type',
                    hintText: 'Enter new vehicle type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  validator: _showAddNewVehicleType
                      ? (value) => value?.isEmpty == true ? 'New vehicle type is required' : null
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addNewVehicleType,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Add'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAddNewVehicleType = false;
                    _newVehicleTypeController.clear();
                    _selectedVehicleType = _vehicleTypes.first;
                  });
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _addNewVehicleType() {
    final newType = _newVehicleTypeController.text.trim();
    if (newType.isNotEmpty && !_vehicleTypes.contains(newType)) {
      setState(() {
        _vehicleTypes.add(newType);
        _selectedVehicleType = newType;
        _showAddNewVehicleType = false;
        _newVehicleTypeController.clear();
      });
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final XFile? photo = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        
        if (photo != null) {
          setState(() {
            _selectedPhoto = photo;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhoto = null;
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value?.isEmpty == true) return '$label is required';
        if (double.tryParse(value!) == null) return 'Enter a valid amount';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: '₹ ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildGateDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGate,
      decoration: InputDecoration(
        labelText: 'Gate Number',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: _gateOptions.map((gate) {
        return DropdownMenuItem(
          value: gate['value'],
          child: Text(gate['label']!),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGate = value!;
        });
      },
    );
  }

  Widget _buildInOutDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedInOut,
      decoration: InputDecoration(
        labelText: 'In/Out',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: _inOutOptions.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedInOut = value!;
        });
      },
      validator: (value) => value?.isEmpty == true ? 'In/Out selection is required' : null,
    );
  }

  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Document (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload photo of road tax receipt or official document',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedPhoto != null) ...[
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_selectedPhoto!.path),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Change Photo'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _removePhoto,
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          InkWell(
            onTap: _pickPhoto,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload photo',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Road tax receipt or official document',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateTimePicker() {
    return InkWell(
      onTap: _selectDateTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date & Time',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalDisplay() {
    double total = _calculateTotal();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '₹ ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    double cisf = double.tryParse(_cisfAmountController.text) ?? 0;
    double kpt = double.tryParse(_kptAmountController.text) ?? 0;
    double customs = double.tryParse(_customsAmountController.text) ?? 0;
    int roadTaxDays = int.tryParse(_roadTaxDaysController.text) ?? 0;
    double roadTaxAmount = roadTaxDays * 50.0; // ₹50 per day as requested
    double other = double.tryParse(_otherChargesController.text) ?? 0;
    
    return cisf + kpt + customs + roadTaxAmount + other;
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final walletService = ref.read(walletServiceProvider);
      
      // Use the selected or newly added vehicle type
      String vehicleType = _showAddNewVehicleType && _newVehicleTypeController.text.isNotEmpty
          ? _newVehicleTypeController.text
          : _selectedVehicleType;
      
      await walletService.createPortExpense(
        dateTime: _selectedDateTime,
        vehicle: vehicleType,
        vehicleNumber: _vehicleNumberController.text,
        gateNo: _selectedGate,
        inOut: _selectedInOut,
        description: _descriptionController.text,
        cisfAmount: double.tryParse(_cisfAmountController.text),
        kptAmount: double.tryParse(_kptAmountController.text),
        customsAmount: double.tryParse(_customsAmountController.text),
        roadTaxDays: int.tryParse(_roadTaxDaysController.text),
        otherCharges: double.tryParse(_otherChargesController.text),
        photoFile: _selectedPhoto,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Refresh wallet data
        ref.refreshWalletData();
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit expense: $e'),
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