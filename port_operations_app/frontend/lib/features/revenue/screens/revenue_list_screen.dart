import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/models/revenue_stream_model.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../services/revenue_service.dart';
import '../../auth/auth_service.dart';

class RevenueListScreen extends ConsumerStatefulWidget {
  const RevenueListScreen({super.key});

  @override
  ConsumerState<RevenueListScreen> createState() => _RevenueListScreenState();
}

class _RevenueListScreenState extends ConsumerState<RevenueListScreen> {
  final _searchController = TextEditingController();
  String? _selectedServiceType;
  String? _selectedUnitType;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await ref.read(revenueStreamProvider.notifier).loadRevenueStreams(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      serviceType: _selectedServiceType,
      unitType: _selectedUnitType,
    );
    
    // Load master data
    await ref.read(revenueStreamProvider.notifier).loadMasterData();
  }

  void _onSearchChanged(String value) {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value) {
        _performSearch();
      }
    });
  }

  void _performSearch() {
    ref.read(revenueStreamProvider.notifier).loadRevenueStreams(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      serviceType: _selectedServiceType,
      unitType: _selectedUnitType,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedServiceType = null;
      _selectedUnitType = null;
    });
    _performSearch();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Revenue Streams'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by party, operation, or remarks',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearSearch();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performSearch();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  bool _hasPermission() {
    final user = ref.read(authStateProvider).user;
    if (user == null) return false;
    return ['admin', 'manager', 'accountant'].contains(user.role);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission()) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Revenue Streams'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        drawer: const AppDrawer(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You do not have permission to access Revenue Streams.\nContact your administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final revenueState = ref.watch(revenueStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue Streams'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showSearchDialog,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Type Filters
                Row(
                  children: [
                    const Text(
                      'Service Type:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', null, _selectedServiceType),
                            ...revenueState.serviceTypes.map((serviceType) =>
                                _buildFilterChip(
                                  serviceType.name,
                                  serviceType.code,
                                  _selectedServiceType,
                                ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Unit Type Filters
                Row(
                  children: [
                    const Text(
                      'Unit Type:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildUnitTypeFilterChip('All', null, _selectedUnitType),
                            ...revenueState.unitTypes.map((unitType) =>
                                _buildUnitTypeFilterChip(
                                  unitType.name,
                                  unitType.code,
                                  _selectedUnitType,
                                ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Search Results Info
                if (_searchController.text.isNotEmpty || _selectedServiceType != null || _selectedUnitType != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Filtered results: ${revenueState.revenueStreams.length} items',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Content Section
          Expanded(
            child: revenueState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : revenueState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Error Loading Data',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              revenueState.error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _refreshData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : revenueState.revenueStreams.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No Revenue Streams',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchController.text.isNotEmpty || _selectedServiceType != null || _selectedUnitType != null
                                      ? 'No revenue streams match your search criteria'
                                      : 'Start by adding your first revenue stream',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => context.push('/revenue/add'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Revenue Stream'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshData,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: revenueState.revenueStreams.length,
                              itemBuilder: (context, index) {
                                final stream = revenueState.revenueStreams[index];
                                return _buildRevenueCard(stream);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/revenue/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, String? selectedValue) {
    final isSelected = selectedValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedServiceType = selected ? value : null;
          });
          _performSearch();
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  Widget _buildUnitTypeFilterChip(String label, String? value, String? selectedValue) {
    final isSelected = selectedValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedUnitType = selected ? value : null;
          });
          _performSearch();
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.secondary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.secondary,
      ),
    );
  }

  Widget _buildRevenueCard(RevenueStream stream) {
    final serviceTypeColor = Color(int.parse(stream.serviceTypeColor.replaceFirst('#', '0xFF')));
    final unitTypeColor = Color(int.parse(stream.unitTypeColorCode.replaceFirst('#', '0xFF')));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/revenue/${stream.id}/detail'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Service Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: serviceTypeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: serviceTypeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      stream.serviceTypeLabel,
                      style: TextStyle(
                        color: serviceTypeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Unit Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: unitTypeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: unitTypeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      stream.unitTypeLabel,
                      style: TextStyle(
                        color: unitTypeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Amount
                  Text(
                    stream.formattedAmount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Main Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Operation Name
                        Text(
                          stream.operationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Party Name
                        Row(
                          children: [
                            Icon(Icons.business, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                stream.party,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        
                        // Date
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(DateTime.parse(stream.date)),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        
                        // Bill Number (if available)
                        if (stream.billNo != null && stream.billNo!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.receipt, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Bill: ${stream.billNo}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Quantity and Rate Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Qty: ${stream.formattedQuantity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Rate: ${stream.formattedRate}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Remarks (if available)
              if (stream.remarks != null && stream.remarks!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          stream.remarks!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Footer with created info
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'By ${stream.createdByName ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(stream.createdAt)),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 