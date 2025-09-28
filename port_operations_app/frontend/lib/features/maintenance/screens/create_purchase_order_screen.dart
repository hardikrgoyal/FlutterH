import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';

import '../../../shared/widgets/vehicle_search_dropdown.dart';
import '../services/po_vendor_service.dart';
import '../services/purchase_order_service.dart';
import '../services/work_order_service.dart';
import '../services/audio_recording_service.dart';
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
  int? _selectedVehicleId;
  String _selectedCategory = 'engine';
  String _status = 'open';
  XFile? _audioFile;
  bool _showAddNewVendor = false;
  String? _selectedVehicleNumber;
  String? _customVehicleNumber;
  bool _forStock = false;
  int? _selectedLinkedWo;
  String? _webAudioBlobUrl;
  
  bool get _isEdit => widget.initialPurchaseOrder != null;
  
  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadExistingData();
    }
  }
  
  void _loadExistingData() {
    final po = widget.initialPurchaseOrder!;
    _selectedVendorId = po.vendor;
    _selectedCategory = po.category;
    _status = po.status;
    _remarkController.text = po.remarkText ?? '';
    _selectedVehicleNumber = po.vehicleNumber;
    _forStock = po.forStock;
    _selectedLinkedWo = po.linkedWo;
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _vehicleOtherController.dispose();
    _newVendorController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedVendorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vendor')),
      );
      return;
    }

    try {
      final purchaseOrderData = {
        'vendor': _selectedVendorId,
        'category': _selectedCategory,
        'status': _status,
        'remark_text': _remarkController.text.trim(),
        'for_stock': _forStock,
        'linked_wo': _selectedLinkedWo,
      };

      // Handle vehicle selection - either vehicle ID or vehicle_other
      if (_selectedVehicleId != null) {
        purchaseOrderData['vehicle'] = _selectedVehicleId;
      } else if (_customVehicleNumber != null && _customVehicleNumber!.isNotEmpty) {
        purchaseOrderData['vehicle_other'] = _customVehicleNumber;
      }

      if (_isEdit) {
        await ref.read(purchaseOrderServiceProvider).updatePurchaseOrder(
          widget.initialPurchaseOrder!.id!,
          purchaseOrderData,
          audioFile: _audioFile,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase order updated successfully')),
        );
      } else {
        await ref.read(purchaseOrderServiceProvider).createPurchaseOrder(
          purchaseOrderData,
          audioFile: _audioFile,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase order created successfully')),
        );
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Error updating purchase order: $e' : 'Error creating purchase order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final poVendorsAsync = ref.watch(poVendorsProvider);
    final workOrdersAsync = ref.watch(workOrdersProvider('open'));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Purchase Order' : 'Create Purchase Order'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor Selection
              Text(
                'Vendor *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              poVendorsAsync.when(
                data: (vendors) => Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedVendorId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select vendor',
                      ),
                      items: vendors.map((vendor) {
                        return DropdownMenuItem(
                          value: vendor.id,
                          child: Text(vendor.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedVendorId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a vendor';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAddNewVendor = !_showAddNewVendor;
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: Text(_showAddNewVendor ? 'Cancel' : 'Add New Vendor'),
                    ),
                    if (_showAddNewVendor) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _newVendorController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'New Vendor Name',
                        ),
                        validator: (value) {
                          if (_showAddNewVendor && (value == null || value.trim().isEmpty)) {
                            return 'Please enter vendor name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (_newVendorController.text.trim().isNotEmpty) {
                            try {
                              await ref.read(poVendorServiceProvider).createPOVendor({
                                'name': _newVendorController.text.trim(),
                                'contact_person': '',
                                'phone': '',
                                'email': '',
                                'address': '',
                              });
                              _newVendorController.clear();
                              setState(() {
                                _showAddNewVendor = false;
                              });
                              ref.invalidate(poVendorsProvider);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error creating vendor: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Create Vendor'),
                      ),
                    ],
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error loading vendors: $error'),
              ),
              
              const SizedBox(height: 24),
              
              // Category Selection
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'engine', child: Text('Engine')),
                  DropdownMenuItem(value: 'hydraulic', child: Text('Hydraulic')),
                  DropdownMenuItem(value: 'bushing', child: Text('Bushing')),
                  DropdownMenuItem(value: 'electrical', child: Text('Electrical')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Vehicle Selection
              Text(
                'Vehicle',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              VehicleSearchDropdown(
                selectedVehicleNumber: _selectedVehicleNumber,
                onVehicleSelected: (vehicleNumber) {
                  setState(() {
                    _selectedVehicleNumber = vehicleNumber;
                    _customVehicleNumber = null;
                  });
                },
                onVehicleObjectSelected: (vehicle) {
                  setState(() {
                    _selectedVehicleId = vehicle?.id;
                    _selectedVehicleNumber = vehicle?.vehicleNumber;
                    _customVehicleNumber = null;
                  });
                },
                onCustomVehicleChanged: (customNumber) {
                  setState(() {
                    _customVehicleNumber = customNumber;
                    _selectedVehicleNumber = null;
                    _selectedVehicleId = null;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // For Stock Checkbox
              CheckboxListTile(
                title: const Text('For Stock'),
                value: _forStock,
                onChanged: (value) {
                  setState(() {
                    _forStock = value ?? false;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Linked Work Order
              Text(
                'Linked Work Order',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              workOrdersAsync.when(
                data: (workOrders) => DropdownButtonFormField<int>(
                  value: _selectedLinkedWo,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select work order (optional)',
                  ),
                  items: workOrders.map((wo) {
                    return DropdownMenuItem(
                      value: wo.id,
                      child: Text('WO-${wo.id} - ${wo.remarkText ?? 'No description'}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLinkedWo = value;
                    });
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error loading work orders: $error'),
              ),
              
              const SizedBox(height: 24),
              
              // Remarks
              Text(
                'Remarks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _remarkController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter remarks...',
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              
              // Audio Recording
              Text(
                'Audio Recording',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_audioFile != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.audiotrack, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Audio recording attached',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _audioFile = null;
                            _webAudioBlobUrl = null;
                          });
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                AudioRecordingWidget(
                  initialAudioPath: _audioFile?.path,
                  onAudioRecorded: (audioPath) async {
                    setState(() {
                      _audioFile = XFile(audioPath);
                      _webAudioBlobUrl = null;
                    });
                  },
                  onCancel: () {
                    setState(() {
                      _audioFile = null;
                      _webAudioBlobUrl = null;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            _isEdit ? 'Update Purchase Order' : 'Create Purchase Order',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
