import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';

import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/vehicle_search_dropdown.dart';
import '../services/vendor_service.dart';
import '../services/purchase_order_service.dart';
import '../services/work_order_service.dart';
import '../services/audio_recording_service.dart';
import '../../auth/auth_service.dart';
import '../../../shared/models/purchase_order_model.dart';

class CreatePurchaseOrderScreen extends ConsumerStatefulWidget {
  final PurchaseOrder? initialPurchaseOrder;
  const CreatePurchaseOrderScreen({super.key, this.initialPurchaseOrder});

  @override
  ConsumerState<CreatePurchaseOrderScreen> createState() => _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState extends ConsumerState<CreatePurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _remarkController = TextEditingController();
  final _vehicleOtherController = TextEditingController();
  final _newVendorController = TextEditingController();
  
  // Form values
  int? _selectedVendorId;
  String _selectedCategory = 'Engine';
  String _status = 'open';
  XFile? _audioFile;
  bool _showAddNewVendor = false;
  String? _selectedVehicleNumber;
  String? _customVehicleNumber;
  bool _forStock = false;
  int? _selectedLinkedWo;
  bool get _isEdit => widget.initialPurchaseOrder != null;
  
  // Dropdown options
  final List<String> _categories = [
    'Engine',
    'Hydraulic', 
    'Bushing',
    'Electrical',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final po = widget.initialPurchaseOrder!;
      _selectedVendorId = po.vendor;
      _selectedCategory = po.categoryDisplay;
      _status = po.status;
      _remarkController.text = po.remarkText ?? '';
      _forStock = po.forStock;
      _selectedVehicleNumber = po.vehicleNumber ?? (po.vehicleOther != null ? 'others' : null);
      _customVehicleNumber = po.vehicleOther;
      if (po.vehicleOther != null) {
        _vehicleOtherController.text = po.vehicleOther!;
      }
    }
  }

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
        title: Text(_isEdit ? 'Edit Purchase Order' : 'Create Purchase Order'),
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
            _buildTargetField(),
            const SizedBox(height: 16),
            _buildLinkedWoField(),
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
              if (value == null && !_showAddNewVendor) {
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

  Widget _buildTargetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('For Stock'),
                value: _forStock,
                onChanged: (value) {
                  setState(() {
                    _forStock = value ?? false;
                    if (_forStock) {
                      _selectedVehicleNumber = null;
                      _customVehicleNumber = null;
                      _vehicleOtherController.clear();
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
        if (!_forStock) ...[
          const SizedBox(height: 8),
          VehicleSearchDropdown(
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
          ),
        ],
      ],
    );
  }

  Widget _buildLinkedWoField() {
    final workOrdersAsync = ref.watch(workOrdersProvider('open'));
    
    return workOrdersAsync.when(
      data: (wos) {
        // Filter: only open WOs and not already linked to any PO
        final availableWOs = wos.where((wo) => wo.status == 'open').toList(); // Show all open WOs (since one WO can have multiple POs)
        
        if (availableWOs.isEmpty) {
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
                        'No open work orders available to link.',
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
                  labelText: 'Link to Work Order (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                items: const [
                  DropdownMenuItem<int>(
                    value: null,
                    child: Text('No WO Link'),
                  ),
                ],
                onChanged: null,
              ),
            ],
          );
        }
        
        return DropdownButtonFormField<int>(
          value: _selectedLinkedWo,
          decoration: const InputDecoration(
            labelText: 'Link to Work Order (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
            hintText: 'Select WO to link with this PO',
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('No WO Link'),
            ),
            ...availableWOs.map((wo) => DropdownMenuItem<int>(
              value: wo.id,
              child: Text('${wo.woId} - ${wo.displayVehicle}'),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedLinkedWo = value;
            });
          },
        );
      },
      loading: () => DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Link to Work Order (Optional)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.link),
        ),
        items: const [],
        onChanged: null,
      ),
      error: (error, stack) => DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Link to Work Order (Optional)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.link),
          errorText: 'Failed to load WOs',
        ),
        items: const [
          DropdownMenuItem<int>(
            value: null,
            child: Text('No WO Link'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedLinkedWo = value;
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
        hintText: 'Enter purchase description and notes',
      ),
      maxLines: 4,
      validator: (value) {
        if (value?.trim().isEmpty ?? true) {
          return 'Please enter purchase description';
        }
        return null;
      },
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
            const SizedBox(height: 8),
            if (_audioFile != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.audiotrack, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Audio recorded: ${_audioFile!.name}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final audioService = ref.read(audioRecordingServiceProvider);
                        await audioService.playAudio(_audioFile!.path);
                      },
                      icon: const Icon(Icons.play_arrow, color: Colors.blue),
                      tooltip: 'Play audio',
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _audioFile = null;
                        });
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete audio',
                    ),
                  ],
                ),
              ),
            ] else ...[
              AudioRecordingWidget(
                initialAudioPath: _audioFile?.path,
                onAudioRecorded: (audioPath) {
                  setState(() {
                    _audioFile = XFile(audioPath);
                  });
                },
                onCancel: () {
                  setState(() {
                    _audioFile = null;
                  });
                },
              ),
            ],
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
      child: Text(
        _isEdit ? 'Save Changes' : 'Create Purchase Order',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }



  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate target selection
    if (!_forStock && (_selectedVehicleNumber == null || _vehicleOtherController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle or choose "For Stock"')),
      );
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

      final purchaseOrderService = ref.read(purchaseOrderServiceProvider);
      
      final purchaseOrderData = {
        'vendor': vendorId,
        'for_stock': _forStock,
        'category': _selectedCategory.toLowerCase(),
        'remark_text': _remarkController.text.trim(),
        'status': _status,
        'linked_wo': _selectedLinkedWo,
      };

      if (!_forStock) {
        purchaseOrderData['vehicle_other'] = _vehicleOtherController.text.trim();
      }

      if (_isEdit) {
        await purchaseOrderService.updatePurchaseOrder(widget.initialPurchaseOrder!.id!, purchaseOrderData);
      } else {
        await purchaseOrderService.createPurchaseOrder(purchaseOrderData, audioFile: _audioFile);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEdit ? 'Purchase order updated successfully' : 'Purchase order created successfully')));
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEdit ? 'Error updating purchase order: $e' : 'Error creating purchase order: $e')));
      }
    }
  }
} 