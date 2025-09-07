import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_model.dart';
import '../../features/vehicles/vehicle_providers.dart';
import '../../core/constants/app_colors.dart';

class VehicleSearchDropdown extends ConsumerStatefulWidget {
  final String? selectedVehicleNumber;
  final Function(String?) onVehicleSelected;
  final Function(Vehicle?)? onVehicleObjectSelected;
  final String? hintText;
  final String? labelText;
  final bool showOthersOption;
  final String? customVehicleNumber;
  final Function(String?)? onCustomVehicleChanged;

  const VehicleSearchDropdown({
    super.key,
    this.selectedVehicleNumber,
    required this.onVehicleSelected,
    this.onVehicleObjectSelected,
    this.hintText = 'Search and select vehicle',
    this.labelText = 'Vehicle Number',
    this.showOthersOption = true,
    this.customVehicleNumber,
    this.onCustomVehicleChanged,
  });

  @override
  ConsumerState<VehicleSearchDropdown> createState() => _VehicleSearchDropdownState();
}

class _VehicleSearchDropdownState extends ConsumerState<VehicleSearchDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customVehicleController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Vehicle> _filteredVehicles = [];
  List<Vehicle> _allVehicles = [];
  bool _showDropdown = false;
  bool _isOthersSelected = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _customVehicleController.addListener(_onCustomVehicleChanged);
    _initializeValues();
  }

  void _initializeValues() {
    if (widget.selectedVehicleNumber == 'others') {
      _isOthersSelected = true;
      _searchController.text = 'Others';
      _customVehicleController.text = widget.customVehicleNumber ?? '';
    } else if (widget.selectedVehicleNumber != null) {
      _searchController.text = widget.selectedVehicleNumber!;
    }
  }

  @override
  void didUpdateWidget(VehicleSearchDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the selected vehicle actually changed
    if (oldWidget.selectedVehicleNumber != widget.selectedVehicleNumber ||
        oldWidget.customVehicleNumber != widget.customVehicleNumber) {
      _initializeValues();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customVehicleController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredVehicles = _allVehicles;
      });
    } else if (query == 'others') {
      setState(() {
        _filteredVehicles = [];
      });
    } else {
      setState(() {
        _filteredVehicles = _allVehicles.where((vehicle) {
          return vehicle.vehicleNumber.toLowerCase().contains(query) ||
                 vehicle.vehicleTypeName.toLowerCase().contains(query) ||
                 (vehicle.ownerName?.toLowerCase().contains(query) ?? false);
        }).toList();
      });
    }
  }

  void _onCustomVehicleChanged() {
    if (widget.onCustomVehicleChanged != null) {
      widget.onCustomVehicleChanged!(_customVehicleController.text);
    }
  }

  void _selectVehicle(String vehicleNumber, [Vehicle? vehicle]) {
    setState(() {
      _searchController.text = vehicleNumber;
      _showDropdown = false;
      _isOthersSelected = vehicleNumber == 'others';
    });
    
    if (_isOthersSelected) {
      widget.onVehicleSelected('others');
      if (widget.onVehicleObjectSelected != null) {
        widget.onVehicleObjectSelected!(null);
      }
    } else {
      widget.onVehicleSelected(vehicleNumber);
      if (widget.onVehicleObjectSelected != null) {
        widget.onVehicleObjectSelected!(vehicle);
      }
    }
    _searchFocusNode.unfocus();
  }

  void _toggleDropdown() {
    setState(() {
      _showDropdown = !_showDropdown;
    });
    if (_showDropdown) {
      _searchFocusNode.requestFocus();
    }
  }

  Widget _buildVehicleItem(Vehicle vehicle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: InkWell(
        onTap: () => _selectVehicle(vehicle.vehicleNumber, vehicle),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vehicle.vehicleNumber,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vehicle.vehicleTypeName,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: vehicle.status == 'active' 
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vehicle.statusDisplay,
                    style: TextStyle(
                      color: vehicle.status == 'active' 
                          ? AppColors.success
                          : AppColors.warning,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (vehicle.ownerName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Owner: ${vehicle.ownerName}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOthersItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: InkWell(
        onTap: () => _selectVehicle('others'),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Text(
              'Others (Enter custom vehicle number)',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedWidget(List<Vehicle> vehicles) {
    // Only initialize vehicles once to prevent rebuild loops
    if (!_isInitialized) {
      _allVehicles = vehicles;
      _filteredVehicles = vehicles;
      _isInitialized = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Field
        TextFormField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            suffixIcon: IconButton(
              icon: Icon(_showDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              onPressed: _toggleDropdown,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onTap: () {
            setState(() {
              _showDropdown = true;
            });
          },
          validator: (value) {
            if (_isOthersSelected) {
              if (_customVehicleController.text.isEmpty) {
                return 'Please enter vehicle number';
              }
            } else if (value?.isEmpty == true && widget.labelText?.contains('Optional') != true) {
              return 'Please select a vehicle';
            }
            return null;
          },
        ),

        // Custom Vehicle Input (shown when Others is selected)
        if (_isOthersSelected) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _customVehicleController,
            decoration: InputDecoration(
              labelText: 'Enter Vehicle Number',
              hintText: 'e.g., GJ01AB1234',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            validator: (value) {
              if (_isOthersSelected && (value?.isEmpty == true)) {
                return 'Vehicle number is required';
              }
              return null;
            },
          ),
        ],

        // Dropdown List
        if (_showDropdown) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Others option (if enabled)
                  if (widget.showOthersOption) _buildOthersItem(),
                  
                  // Vehicle list
                  if (_filteredVehicles.isEmpty && _searchController.text.isNotEmpty && _searchController.text != 'others')
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No vehicles found matching "${_searchController.text}"',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ...(_filteredVehicles.map((vehicle) => _buildVehicleItem(vehicle)).toList()),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final vehiclesAsync = ref.watch(allVehiclesProvider);

        return vehiclesAsync.when(
          data: (vehicles) => _buildLoadedWidget(vehicles),
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: 'Loading vehicles...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ),
          error: (error, stack) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                validator: (value) => value?.isEmpty == true ? 'Vehicle number is required' : null,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load vehicles. Please enter manually.',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 