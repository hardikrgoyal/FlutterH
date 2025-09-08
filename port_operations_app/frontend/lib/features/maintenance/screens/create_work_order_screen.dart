import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/vehicle_search_dropdown.dart';
import '../services/vendor_service.dart';
import '../services/work_order_service.dart';
import '../services/purchase_order_service.dart';
import '../services/audio_recording_service.dart';
import '../../auth/auth_service.dart';

class CreateWorkOrderScreen extends ConsumerStatefulWidget {
  const CreateWorkOrderScreen({super.key});

  @override
  ConsumerState<CreateWorkOrderScreen> createState() => _CreateWorkOrderScreenState();
}

class _CreateWorkOrderScreenState extends ConsumerState<CreateWorkOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _remarkController = TextEditingController();
  final _vehicleOtherController = TextEditingController();
  final _newVendorController = TextEditingController();
  
  // Form values
  int? _selectedVendorId;
  int? _selectedVehicleId;
  String _selectedCategory = 'Engine';
  String _status = 'open';
  XFile? _audioFile;
  bool _showAddNewVendor = false;
  String? _selectedVehicleNumber;
  String? _customVehicleNumber;
  int? _selectedLinkedPo;
  
  // Dropdown options
  final List<String> _categories = [
    'Engine',
    'Hydraulic', 
    'Bushing',
    'Electrical',
    'Other'
  ];

  @override
  void dispose() {
    _remarkController.dispose();
    _vehicleOtherController.dispose();
    _newVendorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Work Order'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildForm(user),
    );
  }

  Widget _buildForm(User? user) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildVendorField(),
            const SizedBox(height: 16),
            _buildVehicleField(),
            const SizedBox(height: 16),
            _buildLinkedPoField(),
            const SizedBox(height: 16),
            _buildCategoryField(),
            const SizedBox(height: 16),
            _buildRemarkField(),
            const SizedBox(height: 16),
            _buildAudioField(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorField() {
    final vendorsAsync = ref.watch(vendorsProvider);
    
    return vendorsAsync.when(
      data: (vendors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            value: _selectedVendorId,
            decoration: const InputDecoration(
              labelText: 'Vendor *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            validator: (value) {
              if (value == null) {
                return 'Please select a vendor';
              }
              return null;
            },
            items: [
              ...vendors.map((vendor) => DropdownMenuItem<int>(
                value: vendor.id,
                child: Text(vendor.name),
              )),
              const DropdownMenuItem(
                value: -1,
                child: Row(
                  children: [
                    Icon(Icons.add, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Add New Vendor', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                if (value == -1) {
                  _showAddNewVendor = true;
                  _selectedVendorId = null;
                } else {
                  _selectedVendorId = value;
                  _showAddNewVendor = false;
                }
              });
            },
          ),
          if (_showAddNewVendor) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _newVendorController,
              decoration: const InputDecoration(
                labelText: 'New Vendor Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (_showAddNewVendor && (value?.trim().isEmpty ?? true)) {
                  return 'Please enter vendor name';
                }
                return null;
              },
            ),
          ],
        ],
      ),
      loading: () => DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Loading vendors...',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.business),
        ),
        items: const [],
        onChanged: null,
      ),
      error: (error, stack) => DropdownButtonFormField<int>(
        decoration: InputDecoration(
          labelText: 'Error loading vendors',
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
          ),
          prefixIcon: Icon(Icons.error, color: Colors.red),
        ),
        items: const [],
        onChanged: null,
      ),
    );
  }

  Widget _buildVehicleField() {
    return VehicleSearchDropdown(
      selectedVehicleNumber: _selectedVehicleNumber,
      customVehicleNumber: _customVehicleNumber,
      labelText: 'Vehicle *',
      hintText: 'Search and select vehicle',
      onVehicleSelected: (vehicleNumber) {
        setState(() {
          _selectedVehicleNumber = vehicleNumber;
          if (vehicleNumber != 'others') {
            _vehicleOtherController.text = vehicleNumber ?? '';
            _customVehicleNumber = null;
          }
        });
      },
      onCustomVehicleChanged: (customVehicle) {
        setState(() {
          _customVehicleNumber = customVehicle;
          _vehicleOtherController.text = customVehicle ?? '';
        });
      },
    );
  }

  Widget _buildLinkedPoField() {
    final purchaseOrdersAsync = ref.watch(purchaseOrdersProvider('open'));
    
    return purchaseOrdersAsync.when(
      data: (pos) {
        // Filter: POs that are not linked to any WO (one-to-one enforcement)
        final availablePOs = pos.where((po) => po.linkedWoIds == null || po.linkedWoIds!.isEmpty).toList();
        
        if (availablePOs.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No unlinked purchase orders available to link.',
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: null,
                decoration: const InputDecoration(
                  labelText: 'Link to Purchase Order (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                items: const [
                  DropdownMenuItem<int>(
                    value: null,
                    child: Text('No PO Link'),
                  ),
                ],
                onChanged: null,
              ),
            ],
          );
        }
        
        return DropdownButtonFormField<int>(
          value: _selectedLinkedPo,
          decoration: const InputDecoration(
            labelText: 'Link to Purchase Order (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
            hintText: 'Select PO to link with this WO',
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('No PO Link'),
            ),
            ...availablePOs.map((po) => DropdownMenuItem<int>(
              value: po.id,
              child: Text('${po.poId} - ${po.displayTarget}'),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedLinkedPo = value;
            });
          },
        );
      },
      loading: () => DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Link to Purchase Order (Optional)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.link),
        ),
        items: const [],
        onChanged: null,
      ),
      error: (error, stack) => DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Link to Purchase Order (Optional)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.link),
          errorText: 'Failed to load POs',
        ),
        items: const [
          DropdownMenuItem<int>(
            value: null,
            child: Text('No PO Link'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedLinkedPo = value;
          });
        },
      ),
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: _categories.map((category) => DropdownMenuItem<String>(
        value: category,
        child: Text(category),
      )).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
    );
  }

  Widget _buildRemarkField() {
    return TextFormField(
      controller: _remarkController,
      decoration: const InputDecoration(
        labelText: 'Remarks (Optional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.notes),
        hintText: 'Enter work description and notes, or use audio note below',
      ),
      maxLines: 4,
      // Removed validation - now optional since audio can be used instead
    );
  }

    Widget _buildAudioField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mic, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Audio Note (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AudioRecordingWidget(
              onAudioRecorded: (audioPath) {
                setState(() {
                  _audioFile = XFile(audioPath);
                });
              },
              onCancel: () {
                // Handle cancel if needed
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text(
        'Create Work Order',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }



  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if either text remarks or audio is provided
    final hasTextRemarks = _remarkController.text.trim().isNotEmpty;
    final hasAudio = _audioFile != null;
    
    if (!hasTextRemarks && !hasAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide either text remarks or an audio note'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      int vendorId = _selectedVendorId ?? 0;
      
      // Create new vendor if needed
      if (_showAddNewVendor && _newVendorController.text.trim().isNotEmpty) {
        final vendorService = ref.read(vendorServiceProvider);
        final newVendor = await vendorService.createVendor({
          'name': _newVendorController.text.trim(),
        });
        vendorId = newVendor.id;
      }

      final workOrderService = ref.read(workOrderServiceProvider);
      
      final workOrderData = {
        'vendor': vendorId,
        'vehicle_other': _vehicleOtherController.text.trim(),
        'category': _selectedCategory.toLowerCase(),
        'remark_text': _remarkController.text.trim(),
        'status': _status,
        'linked_po': _selectedLinkedPo,
      };

      await workOrderService.createWorkOrder(workOrderData, audioFile: _audioFile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Work order created successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating work order: $e')),
        );
      }
    }
  }
} 