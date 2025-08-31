import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../wallet_service.dart';
import '../wallet_provider.dart';

class CreateExpenseScreen extends ConsumerStatefulWidget {
  const CreateExpenseScreen({super.key});

  @override
  ConsumerState<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends ConsumerState<CreateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cisfAmountController = TextEditingController(text: '50.00');
  final _kptAmountController = TextEditingController(text: '100.00');
  final _customsAmountController = TextEditingController(text: '75.00');
  final _roadTaxDaysController = TextEditingController(text: '1');
  final _otherChargesController = TextEditingController(text: '0.00');

  String _selectedGate = 'gate_1';
  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = false;

  final List<Map<String, String>> _gateOptions = [
    {'value': 'gate_1', 'label': 'Gate 1'},
    {'value': 'gate_2', 'label': 'Gate 2'},
    {'value': 'gate_3', 'label': 'Gate 3'},
    {'value': 'main_gate', 'label': 'Main Gate'},
  ];

  @override
  void dispose() {
    _vehicleController.dispose();
    _vehicleNumberController.dispose();
    _descriptionController.dispose();
    _cisfAmountController.dispose();
    _kptAmountController.dispose();
    _customsAmountController.dispose();
    _roadTaxDaysController.dispose();
    _otherChargesController.dispose();
    super.dispose();
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
              _buildTextField(
                controller: _vehicleController,
                label: 'Vehicle Type',
                hint: 'e.g., Truck, Container',
                validator: (value) => value?.isEmpty == true ? 'Vehicle type is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _vehicleNumberController,
                label: 'Vehicle Number',
                hint: 'e.g., GJ01AB1234',
                validator: (value) => value?.isEmpty == true ? 'Vehicle number is required' : null,
              ),
              const SizedBox(height: 16),
              _buildGateDropdown(),
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
                hint: '100.00',
              ),
              const SizedBox(height: 16),
              _buildAmountField(
                controller: _customsAmountController,
                label: 'Customs Amount',
                hint: '75.00',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _roadTaxDaysController,
                label: 'Road Tax Days',
                hint: '1',
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

  Widget _buildDateTimePicker() {
    return InkWell(
      onTap: () => _selectDateTime(),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date & Time',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime),
          style: const TextStyle(fontSize: 16),
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
    double roadTaxAmount = roadTaxDays * 200.0; // ₹200 per day
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
      
      await walletService.createPortExpense(
        dateTime: _selectedDateTime,
        vehicle: _vehicleController.text,
        vehicleNumber: _vehicleNumberController.text,
        gateNo: _selectedGate,
        description: _descriptionController.text,
        cisfAmount: double.tryParse(_cisfAmountController.text),
        kptAmount: double.tryParse(_kptAmountController.text),
        customsAmount: double.tryParse(_customsAmountController.text),
        roadTaxDays: int.tryParse(_roadTaxDaysController.text),
        otherCharges: double.tryParse(_otherChargesController.text),
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