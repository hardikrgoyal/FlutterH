import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/vehicle_model.dart';
import '../vehicle_providers.dart';

class AddDocumentScreen extends ConsumerStatefulWidget {
  final Vehicle vehicle;
  final VehicleDocument? editDocument;
  final VehicleDocument? renewDocument;
  
  const AddDocumentScreen({
    super.key, 
    required this.vehicle,
    this.editDocument,
    this.renewDocument,
  });

  @override
  ConsumerState<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends ConsumerState<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _notesController = TextEditingController();

  DocumentType? _selectedDocumentType;
  bool _isLoading = false;
  XFile? _selectedFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeForm();
    // Pre-load document types
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentTypesProvider);
    });
  }

  void _initializeForm() {
    if (widget.editDocument != null) {
      final doc = widget.editDocument!;
      _documentNumberController.text = doc.documentNumber;
      _issueDateController.text = doc.issueDate ?? '';
      _expiryDateController.text = doc.expiryDate;
      _notesController.text = doc.notes ?? '';
    } else if (widget.renewDocument != null) {
      final doc = widget.renewDocument!;
      _issueDateController.text = DateTime.now().toIso8601String().split('T')[0];
      _notesController.text = 'Renewed from ${doc.documentNumber}';
    }
  }

  void _initializeDocumentType(List<DocumentType> types) {
    if (types.isEmpty) return;
    
    if (widget.editDocument != null) {
      _selectedDocumentType = types.firstWhere(
        (type) => type.value == widget.editDocument!.documentType,
        orElse: () => types.first,
      );
    } else if (widget.renewDocument != null) {
      _selectedDocumentType = types.firstWhere(
        (type) => type.value == widget.renewDocument!.documentType,
        orElse: () => types.first,
      );
    } else if (_selectedDocumentType == null) {
      // Default to first document type if none selected
      _selectedDocumentType = types.first;
    }
  }

  Future<void> _pickFile() async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
                    if (file != null) {
                      setState(() {
                        _selectedFile = file;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
                    if (file != null) {
                      setState(() {
                        _selectedFile = file;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: const Text('Choose File'),
                  onTap: () async {
                    Navigator.pop(context);
                    // For file picking, we'll use the same image picker for now
                    // In a real app, you might want to use file_picker package for documents
                    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
                    if (file != null) {
                      setState(() {
                        _selectedFile = file;
                      });
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editDocument != null;
    final isRenewal = widget.renewDocument != null;
    
    String title;
    if (isEdit) {
      title = 'Edit Document';
    } else if (isRenewal) {
      title = 'Renew Document';
    } else {
      title = 'Add Document';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVehicleInfo(),
              const SizedBox(height: 24),
              _buildDocumentTypeField(isEdit), // Allow dropdown selection for renewals
              const SizedBox(height: 16),
              _buildDocumentNumberField(),
              const SizedBox(height: 16),
              _buildIssueDateField(),
              const SizedBox(height: 16),
              _buildExpiryDateField(),
              const SizedBox(height: 16),
              _buildFileUploadField(),
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 32),
              _buildSubmitButton(isEdit, isRenewal),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleInfo() {
    return Card(
      color: AppColors.grey100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.directions_car, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.vehicle.vehicleNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.vehicle.vehicleTypeName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTypeField(bool isReadOnly) {
    return Consumer(
      builder: (context, ref, child) {
        final documentTypesAsync = ref.watch(documentTypesProvider);
        
        return documentTypesAsync.when(
          data: (documentTypes) {
            // Debug information
            print('📄 Document types loaded: ${documentTypes.length}');
            if (widget.renewDocument != null) {
              print('🔄 Renewing document type: "${widget.renewDocument!.documentType}"');
            }
            print('✅ Selected document type: "${_selectedDocumentType?.value}"');
            
            // Ensure we have document types to work with
            if (documentTypes.isEmpty) {
              return const Text('No document types available');
            }
            
            // Initialize document type if not already set
            if (_selectedDocumentType == null) {
              // Use a post-frame callback to set state properly
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    if (widget.editDocument != null) {
                      _selectedDocumentType = documentTypes.firstWhere(
                        (type) => type.value == widget.editDocument!.documentType,
                        orElse: () => documentTypes.first,
                      );
                    } else if (widget.renewDocument != null) {
                      _selectedDocumentType = documentTypes.firstWhere(
                        (type) => type.value == widget.renewDocument!.documentType,
                        orElse: () => documentTypes.first,
                      );
                    } else {
                      _selectedDocumentType = documentTypes.first;
                    }
                  });
                }
              });
            }
            
            return DropdownButtonFormField<DocumentType>(
              decoration: InputDecoration(
                labelText: 'Document Type *',
                border: const OutlineInputBorder(),
                enabled: !isReadOnly,
              ),
              value: _selectedDocumentType,
              items: documentTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                );
              }).toList(),
              onChanged: isReadOnly ? null : (value) {
                setState(() {
                  _selectedDocumentType = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Document type is required';
                }
                return null;
              },
            );
          },
          loading: () => const Column(
            children: [
              LinearProgressIndicator(),
              SizedBox(height: 8),
              Text('Loading document types...'),
            ],
          ),
          error: (error, stack) => Column(
            children: [
              const Icon(Icons.error, color: Colors.red),
              Text('Failed to load document types: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(documentTypesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentNumberField() {
    return TextFormField(
      controller: _documentNumberController,
      decoration: const InputDecoration(
        labelText: 'Document Number *',
        border: OutlineInputBorder(),
        hintText: 'Policy No., RC No., Certificate No., etc.',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Document number is required';
        }
        return null;
      },
    );
  }

  Widget _buildIssueDateField() {
    return TextFormField(
      controller: _issueDateController,
      decoration: const InputDecoration(
        labelText: 'Issue Date',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () => _selectDate(context, _issueDateController),
    );
  }

  Widget _buildExpiryDateField() {
    return TextFormField(
      controller: _expiryDateController,
      decoration: const InputDecoration(
        labelText: 'Expiry Date *',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () => _selectDate(context, _expiryDateController),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Expiry date is required';
        }
        return null;
      },
    );
  }

  Widget _buildFileUploadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedFile != null ? Icons.attach_file : Icons.upload_file,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFile != null
                            ? 'File: ${_selectedFile!.name}'
                            : 'Upload Document (PDF, JPG, PNG)',
                        style: TextStyle(
                          color: _selectedFile != null ? Colors.black87 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Browse'),
            ),
          ],
        ),
        if (_selectedFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Selected: ${_selectedFile!.name}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedFile = null;
                    });
                  },
                  child: const Text('Remove'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSubmitButton(bool isEdit, bool isRenewal) {
    String buttonText;
    if (isEdit) {
      buttonText = 'Update Document';
    } else if (isRenewal) {
      buttonText = 'Renew Document';
    } else {
      buttonText = 'Add Document';
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _submitForm(isEdit, isRenewal),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: AppColors.white)
            : Text(buttonText),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  void _submitForm(bool isEdit, bool isRenewal) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final documentData = {
        'vehicle': widget.vehicle.id,
        'document_type': _selectedDocumentType!.value,
        'document_number': _documentNumberController.text.trim(),
        'expiry_date': _expiryDateController.text.trim(),
        if (_issueDateController.text.trim().isNotEmpty)
          'issue_date': _issueDateController.text.trim(),
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      };

      if (isEdit) {
        await ref.read(vehicleServiceProvider).updateDocumentWithFile(
          widget.editDocument!.id,
          documentData,
          _selectedFile,
        );
      } else if (isRenewal) {
        await ref.read(vehicleServiceProvider).renewDocumentWithFile(
          widget.renewDocument!.id,
          documentData,
          _selectedFile,
        );
      } else {
        await ref.read(vehicleServiceProvider).createDocumentWithFile(
          documentData,
          _selectedFile,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document ${isEdit ? 'updated' : isRenewal ? 'renewed' : 'added'} successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isEdit ? 'update' : isRenewal ? 'renew' : 'add'} document: $e'),
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