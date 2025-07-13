import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/models/labour_cost_model.dart';
import '../../../shared/models/cargo_operation_model.dart';
import '../../../shared/models/contractor_model.dart';
import '../labour_service.dart';
import '../../operations/operations_service.dart';
import '../../contractors/contractor_service.dart';
import '../../auth/auth_service.dart';
import '../../rate_master/rate_master_service.dart';

class LabourCostFormScreen extends ConsumerStatefulWidget {
  final int? labourCostId;
  final int? operationId;

  const LabourCostFormScreen({
    super.key,
    this.labourCostId,
    this.operationId,
  });

  @override
  ConsumerState<LabourCostFormScreen> createState() => _LabourCostFormScreenState();
}

class _LabourCostFormScreenState extends ConsumerState<LabourCostFormScreen> 
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();
  final _contractorNameController = TextEditingController();
  final _labourCountController = TextEditingController();
  final _rateController = TextEditingController();
  final _remarksController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  
  bool _isLoading = false;
  LabourCost? _existingLabourCost;
  List<CargoOperation> _operations = [];
  List<ContractorMaster> _contractors = [];
  double _calculatedAmount = 0.0;
  
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedInvoiceDate;
  int? _selectedOperation;
  int? _selectedContractor;
  String? _selectedLabourType;
  String? _selectedWorkType;
  String? _selectedShift;
  bool? _invoiceReceived;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _contractorNameController.dispose();
    _labourCountController.dispose();
    _rateController.dispose();
    _remarksController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Load operations
      final operationsService = ref.read(operationsServiceProvider);
      final operations = await operationsService.getOperations();
      
      // Load contractors
      final contractorService = ref.read(contractorServiceProvider);
      final contractors = await contractorService.getContractors();
      
      if (!mounted) return;
      
      setState(() {
        _operations = operations;
        _contractors = contractors;
      });
      
      // Set initial operation if provided
      if (widget.operationId != null) {
        _selectedOperation = widget.operationId;
      }
      
      // Load existing labour cost if editing
      if (widget.labourCostId != null) {
        final labourService = ref.read(labourServiceProvider);
        final existingLabourCost = await labourService.getLabourCost(widget.labourCostId!);
        
        if (!mounted) return;
        
        setState(() {
          _existingLabourCost = existingLabourCost;
        });
        _populateForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateForm() {
    if (_existingLabourCost != null) {
      _contractorNameController.text = _existingLabourCost!.contractorName ?? '';
      _labourCountController.text = _existingLabourCost!.labourCountTonnage.toString();
      _rateController.text = (_existingLabourCost!.rate ?? 0.0).toString();
      _remarksController.text = _existingLabourCost!.remarks ?? '';
      _invoiceNumberController.text = _existingLabourCost!.invoiceNumber ?? '';
      
      _selectedDate = _existingLabourCost!.date;
      _selectedInvoiceDate = _existingLabourCost!.invoiceDate;
      _selectedOperation = _existingLabourCost!.operation;
      _selectedContractor = _existingLabourCost!.contractor;
      _selectedLabourType = _existingLabourCost!.labourType;
      _selectedWorkType = _existingLabourCost!.workType;
      _selectedShift = _existingLabourCost!.shift;
      _invoiceReceived = _existingLabourCost!.invoiceReceived ?? false;
      
      _calculateAmount();
    }
  }

  void _calculateAmount() {
    final countTonnage = double.tryParse(_labourCountController.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    setState(() {
      _calculatedAmount = countTonnage * rate;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final user = ref.watch(authStateProvider).user;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.labourCostId != null ? 'Edit Labour Cost' : 'Add Labour Cost'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
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
                              MdiIcons.accountGroup,
                              size: 32,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.labourCostId != null ? 'Edit Labour Cost' : 'New Labour Cost Entry',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.labourCostId != null 
                                        ? 'Update labour cost information'
                                        : 'Add labour cost for cargo operation',
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
                    _buildSectionHeader('Operation Details', MdiIcons.shipWheel),
                    const SizedBox(height: 16),
                    
                    _buildDropdownField(
                      label: 'Operation',
                      value: _selectedOperation,
                      items: _operations.map((op) => DropdownMenuItem(
                        value: op.id,
                        child: Text(op.operationName),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedOperation = value;
                        });
                      },
                      icon: Icons.business,
                      validator: (value) {
                        if (value == null) {
                          return 'Please select an operation';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildDateField(),
                    const SizedBox(height: 24),

                    // Labour Details Section
                    _buildSectionHeader('Labour Details', MdiIcons.accountMultiple),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Contractor',
                            value: _selectedContractor,
                            items: _contractors.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            )).toList(),
                            onChanged: _onContractorChanged,
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null) {
                                return 'Contractor is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (user.isAdmin || user.isManager) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _showAddContractorDialog,
                            icon: const Icon(Icons.add_circle),
                            tooltip: 'Add New Contractor',
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildDropdownField(
                      label: 'Labour Type',
                      value: _selectedLabourType,
                      items: LabourCost.labourTypeChoices.map((choice) => DropdownMenuItem(
                        value: choice['value'],
                        child: Text(choice['label']!),
                      )).toList(),
                      onChanged: _onLabourTypeChanged,
                      icon: Icons.group,
                    ),
                    const SizedBox(height: 16),

                    // Shift field - only for casual labour
                    if (_selectedLabourType == 'casual') ...[
                      _buildDropdownField(
                        label: 'Shift',
                        value: _selectedShift,
                        items: LabourCost.shiftChoices.map((choice) => DropdownMenuItem(
                          value: choice['value'],
                          child: Text(choice['label']!),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedShift = value;
                          });
                        },
                        icon: Icons.schedule,
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildDropdownField(
                      label: 'Work Type',
                      value: _selectedWorkType,
                      items: LabourCost.workTypeChoices.map((choice) => DropdownMenuItem(
                        value: choice['value'],
                        child: Text(choice['label']!),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedWorkType = value!;
                        });
                      },
                      icon: Icons.work,
                    ),
                    const SizedBox(height: 16),

                    // Quantity field - accessible to all users
                    _buildTextField(
                      controller: _labourCountController,
                      label: _selectedLabourType == 'casual' 
                          ? 'Number of Workers'
                          : _selectedLabourType == 'tonnes'
                              ? 'Tonnage'
                              : 'Quantity',
                      hint: _selectedLabourType == 'casual' 
                          ? 'e.g., 10'
                          : _selectedLabourType == 'tonnes'
                              ? 'e.g., 25.5'
                              : 'e.g., 1',
                      icon: Icons.numbers,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'This field is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Value must be greater than 0';
                        }
                        return null;
                      },
                      onChanged: (value) => _calculateAmount(),
                    ),
                    const SizedBox(height: 24),

                    // Cost Details Section - Only for managers and admins when editing
                    if (user.canAccessCostDetails && widget.labourCostId != null) ...[
                      _buildSectionHeader('Cost Details', Icons.currency_rupee),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _rateController,
                        label: 'Rate (₹)',
                        hint: 'e.g., 500.00',
                        icon: Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Rate is required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Rate must be greater than 0';
                          }
                          return null;
                        },
                        onChanged: (value) => _calculateAmount(),
                      ),
                      const SizedBox(height: 16),

                      // Calculated Amount Display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calculate,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Calculated Total Amount',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${NumberFormat('#,##0.00').format(_calculatedAmount)}',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Additional Information Section
                    _buildSectionHeader('Additional Information', Icons.note),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _remarksController,
                      label: 'Remarks (Optional)',
                      hint: 'Any additional notes or comments...',
                      icon: Icons.note,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Invoice Tracking Section - Only for users with invoice tracking access when editing
                    if (user.canAccessInvoiceTracking && widget.labourCostId != null) ...[
                      _buildSectionHeader('Invoice Tracking', Icons.receipt_long),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _invoiceNumberController,
                        label: 'Invoice Number (Optional)',
                        hint: 'e.g., INV-2024-001',
                        icon: Icons.receipt,
                      ),
                      const SizedBox(height: 16),

                      _buildDropdownField(
                        label: 'Invoice Status',
                        value: _invoiceReceived,
                        items: const [
                          DropdownMenuItem<bool>(
                            value: false,
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem<bool>(
                            value: true,
                            child: Text('Received'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _invoiceReceived = value ?? false;
                            if (value == true && _selectedInvoiceDate == null) {
                              _selectedInvoiceDate = DateTime.now();
                            } else if (value != true) {
                              _selectedInvoiceDate = null;
                            }
                          });
                        },
                        icon: Icons.assignment_turned_in,
                      ),
                      const SizedBox(height: 16),

                      if (_invoiceReceived == true) ...[
                        _buildInvoiceDateField(),
                        const SizedBox(height: 16),
                      ],

                      // Invoice Status Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getInvoiceStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getInvoiceStatusColor().withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getInvoiceStatusIcon(),
                              color: _getInvoiceStatusColor(),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Invoice Status',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _getInvoiceStatusColor(),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getInvoiceStatusText(),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _getInvoiceStatusColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => context.pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(widget.labourCostId != null ? 'Update Labour Cost' : 'Add Labour Cost'),
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
    void Function(String)? onChanged,
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
      onChanged: onChanged,
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
                    'Work Date',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
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

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for shift when labour type is casual
    if (_selectedLabourType == 'casual' && _selectedShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shift is required for casual labour type'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Additional validation for rate when editing existing entries and user has cost access
    final user = ref.read(authStateProvider).user;
    if (user == null) return;
    
    if (widget.labourCostId != null && user.canAccessCostDetails && _rateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rate is required when editing'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).user;
      if (user == null) return;
      
      // For new entries, fetch rate from Rate Master
      double? finalRate;
      if (widget.labourCostId == null) {
        // New entry - fetch rate from Rate Master
        try {
          final rateMasterService = ref.read(rateMasterServiceProvider);
          finalRate = await rateMasterService.getRate(_selectedContractor!, _selectedLabourType!);
        } catch (e) {
          // If rate not found in master, set to null
          finalRate = null;
        }
      } else {
        // Editing existing entry - use rate from form if user has access
        if (user.canAccessCostDetails && _rateController.text.trim().isNotEmpty) {
          finalRate = double.parse(_rateController.text);
        } else {
          finalRate = _existingLabourCost?.rate;
        }
      }
      
      final labourCost = LabourCost(
        id: _existingLabourCost?.id,
        operation: _selectedOperation!,
        date: _selectedDate,
        contractor: _selectedContractor!,
        labourType: _selectedLabourType!,
        workType: _selectedWorkType!,
        shift: _selectedShift,
        labourCountTonnage: double.parse(_labourCountController.text),
        rate: finalRate,
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        // Only include invoice tracking fields for users with access when editing
        invoiceNumber: (user.canAccessInvoiceTracking && widget.labourCostId != null)
            ? (_invoiceNumberController.text.trim().isEmpty ? null : _invoiceNumberController.text.trim())
            : null,
        invoiceReceived: (user.canAccessInvoiceTracking && widget.labourCostId != null) ? _invoiceReceived : null,
        invoiceDate: (user.canAccessInvoiceTracking && widget.labourCostId != null) ? _selectedInvoiceDate : null,
      );

      if (widget.labourCostId != null) {
        await ref.read(labourCostProvider.notifier).updateLabourCost(
          widget.labourCostId!,
          labourCost,
        );
      } else {
        await ref.read(labourCostProvider.notifier).addLabourCost(labourCost);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.labourCostId != null
                  ? 'Labour cost updated successfully'
                  : 'Labour cost added successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to save labour cost';
        
        // Provide more specific error messages
        if (e.toString().contains('Date has wrong format')) {
          errorMessage = 'Invalid date format. Please try again.';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Invalid data provided. Please check your inputs.';
        } else if (e.toString().contains('401')) {
          errorMessage = 'You are not authorized to perform this action.';
        } else if (e.toString().contains('403')) {
          errorMessage = 'You do not have permission to perform this action.';
        } else if (e.toString().contains('404')) {
          errorMessage = 'The selected operation was not found.';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Server error. Please try again later.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Network error. Please check your connection.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _submitForm,
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getInvoiceStatusColor() {
    if (_invoiceReceived == true) {
      return AppColors.success;
    } else {
      return AppColors.warning;
    }
  }

  IconData _getInvoiceStatusIcon() {
    if (_invoiceReceived == true) {
      return Icons.check_circle;
    } else {
      return Icons.pending;
    }
  }

  String _getInvoiceStatusText() {
    if (_invoiceReceived == true) {
      return 'Received';
    } else {
      return 'Pending';
    }
  }

  Widget _buildInvoiceDateField() {
    return InkWell(
      onTap: _selectInvoiceDate,
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
                    'Invoice Date',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_selectedInvoiceDate ?? DateTime.now()),
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

  Future<void> _selectInvoiceDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedInvoiceDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedInvoiceDate) {
      setState(() {
        _selectedInvoiceDate = picked;
      });
    }
  }

  Future<void> _showAddContractorDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final nameController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Add New Contractor'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Contractor Name *',
              hintText: 'e.g., ABC Labour Contractors',
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop(value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Contractor name is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(name);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    
    // Handle the result after dialog is completely closed
    if (result != null && result.isNotEmpty && mounted) {
      await _createContractor(result);
    }
  }
  
  Future<void> _createContractor(String contractorName) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Adding contractor...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      final contractor = ContractorMaster(name: contractorName);
      final contractorService = ref.read(contractorServiceProvider);
      final newContractor = await contractorService.createContractor(contractor);
      
      // Refresh contractors list
      final contractors = await contractorService.getContractors();
      
      if (mounted) {
        setState(() {
          _contractors = contractors;
          _selectedContractor = newContractor.id;
        });
        
        // Clear any existing snackbars and show success
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contractor "$contractorName" added successfully'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add contractor: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _onLabourTypeChanged(String? labourType) async {
    setState(() {
      _selectedLabourType = labourType;
      _selectedShift = null; // Reset shift when labour type changes
    });
    
    // Auto-fetch rate if contractor and labour type are selected
    if (_selectedContractor != null && labourType != null) {
      await _fetchRate();
    }
    
    // For fixed labour type, set labour count to 1
    if (labourType == 'fixed') {
      _labourCountController.text = '1';
    }
  }

  Future<void> _onContractorChanged(int? contractorId) async {
    setState(() {
      _selectedContractor = contractorId;
    });
    
    // Auto-fetch rate if contractor and labour type are selected
    if (contractorId != null && _selectedLabourType != null) {
      await _fetchRate();
    }
  }

  Future<void> _fetchRate() async {
    if (_selectedContractor == null || _selectedLabourType == null) return;
    
    // Only fetch rate for users with cost access when editing existing entries
    final user = ref.read(authStateProvider).user;
    if (user == null || !user.canAccessCostDetails || widget.labourCostId == null) return;
    
    try {
      final rateMasterService = ref.read(rateMasterServiceProvider);
      final rate = await rateMasterService.getRate(_selectedContractor!, _selectedLabourType!);
      
      if (rate != null) {
        setState(() {
          _rateController.text = rate.toString();
        });
        _calculateAmount();
      }
    } catch (e) {
      // If rate not found, user will need to enter manually
      print('Rate not found for contractor $_selectedContractor and labour type $_selectedLabourType');
    }
  }
} 