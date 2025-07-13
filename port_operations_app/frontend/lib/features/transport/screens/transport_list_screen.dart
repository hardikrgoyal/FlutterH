import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/models/transport_detail_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../services/transport_service.dart';
import '../../auth/auth_service.dart';

class TransportListScreen extends ConsumerStatefulWidget {
  const TransportListScreen({super.key});

  @override
  ConsumerState<TransportListScreen> createState() => _TransportListScreenState();
}

class _TransportListScreenState extends ConsumerState<TransportListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedContractType;
  int? _selectedOperationId;

  final List<String> _contractTypes = ['per_trip', 'per_mt', 'daily', 'lumpsum'];
  final Map<String, String> _contractTypeLabels = {
    'per_trip': 'Per Trip',
    'per_mt': 'Per MT',
    'daily': 'Daily',
    'lumpsum': 'Lumpsum',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final notifier = ref.read(transportDetailProvider.notifier);
    notifier.loadOperations();
    notifier.loadTransportDetails(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      contractType: _selectedContractType,
      operationId: _selectedOperationId,
    );
  }

  void _applyFilters() {
    _loadData();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedContractType = null;
      _selectedOperationId = null;
      _searchController.clear();
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final transportState = ref.watch(transportDetailProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    // Check if user has permission (only admin and manager)
    if (user?.role != 'admin' && user?.role != 'manager') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transport Details'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Only administrators and managers can access transport details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by vehicle, party, or bill number...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  onSubmitted: (_) => _applyFilters(),
                ),
                const SizedBox(height: 12),
                // Filters row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Contract Type filter
                      _buildFilterDropdown(
                        'Contract Type',
                        _selectedContractType,
                        _contractTypes.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(_contractTypeLabels[type] ?? type),
                        )).toList(),
                        (value) {
                          setState(() {
                            _selectedContractType = value;
                          });
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      // Operation filter
                      _buildOperationFilter(),
                      const SizedBox(width: 8),
                      // Clear filters
                      if (_selectedContractType != null || _selectedOperationId != null || _searchQuery.isNotEmpty)
                        FilterChip(
                          label: const Text('Clear Filters'),
                          onSelected: (_) => _clearFilters(),
                          backgroundColor: Colors.red.shade50,
                          selectedColor: Colors.red.shade100,
                          side: BorderSide(color: Colors.red.shade300),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: transportState.isLoading
                ? const LoadingWidget()
                : transportState.error != null
                    ? AppErrorWidget(
                        message: transportState.error!,
                        onRetry: _loadData,
                      )
                    : _buildTransportList(transportState.transportDetails),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transport/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterDropdown<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    void Function(T?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          hint: Text(label),
          value: value,
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text('All $label'),
            ),
            ...items,
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOperationFilter() {
    final operations = ref.watch(transportDetailProvider).operations;
    
    return _buildFilterDropdown(
      'Operation',
      _selectedOperationId,
      operations.map((op) => DropdownMenuItem(
        value: op.id,
        child: Text(op.operationName),
      )).toList(),
      (value) {
        setState(() {
          _selectedOperationId = value;
        });
        _applyFilters();
      },
    );
  }

  Widget _buildTransportList(List<TransportDetail> transportDetails) {
    final filteredTransports = _filterTransports(transportDetails);

    if (filteredTransports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedContractType != null || _selectedOperationId != null
                  ? 'No transport details found matching your filters'
                  : 'No transport details available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first transport detail to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTransports.length,
        itemBuilder: (context, index) {
          final transport = filteredTransports[index];
          return _buildTransportCard(transport);
        },
      ),
    );
  }

  List<TransportDetail> _filterTransports(List<TransportDetail> transports) {
    return transports.where((transport) {
      final matchesSearch = _searchQuery.isEmpty ||
          transport.vehicle.toLowerCase().contains(_searchQuery) ||
          transport.vehicleNumber.toLowerCase().contains(_searchQuery) ||
          transport.partyName.toLowerCase().contains(_searchQuery) ||
          (transport.billNo?.toLowerCase().contains(_searchQuery) ?? false);

      return matchesSearch;
    }).toList();
  }

  Widget _buildTransportCard(TransportDetail transport) {
    final contractTypeColor = _getContractTypeColor(transport.contractType);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/transport/${transport.id}/detail'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: contractTypeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: contractTypeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      transport.contractTypeDisplay ?? _contractTypeLabels[transport.contractType] ?? transport.contractType,
                      style: TextStyle(
                        color: contractTypeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd MMM yyyy').format(DateTime.parse(transport.date)),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Vehicle Info
              Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      transport.displayTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Party and Operation
              Row(
                children: [
                  Icon(Icons.business, color: Colors.grey.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      transport.partyName,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.work_outline, color: Colors.grey.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      transport.operationName,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Quantity and Cost
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'Quantity',
                      transport.quantity,
                      Icons.scale,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoChip(
                      'Cost',
                      transport.formattedCost,
                      Icons.currency_rupee,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              // Bill Number if available
              if (transport.billNo != null && transport.billNo!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.grey.shade600, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Bill: ${transport.billNo}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getContractTypeColor(String contractType) {
    switch (contractType) {
      case 'per_trip':
        return Colors.blue;
      case 'per_mt':
        return Colors.green;
      case 'daily':
        return Colors.orange;
      case 'lumpsum':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
} 