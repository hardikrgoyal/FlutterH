import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/models/miscellaneous_cost_model.dart';
import '../services/miscellaneous_service.dart';
import '../../auth/auth_service.dart';

class MiscellaneousListScreen extends ConsumerStatefulWidget {
  const MiscellaneousListScreen({super.key});

  @override
  ConsumerState<MiscellaneousListScreen> createState() => _MiscellaneousListScreenState();
}

class _MiscellaneousListScreenState extends ConsumerState<MiscellaneousListScreen> {
  final _searchController = TextEditingController();
  String? _selectedCostType;
  int? _selectedOperationId;

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

  Future<void> _loadData() async {
    await Future.wait([
      ref.read(miscellaneousCostProvider.notifier).loadMiscellaneousCosts(),
      ref.read(miscellaneousCostProvider.notifier).loadOperations(),
    ]);
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _performSearch() {
    ref.read(miscellaneousCostProvider.notifier).loadMiscellaneousCosts(
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      costType: _selectedCostType,
      operationId: _selectedOperationId,
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Miscellaneous Costs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by party, remarks',
                hintText: 'Enter search term',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _performSearch();
              Navigator.of(context).pop();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCostType = null;
      _selectedOperationId = null;
      _searchController.clear();
    });
    ref.read(miscellaneousCostProvider.notifier).loadMiscellaneousCosts();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final miscState = ref.watch(miscellaneousCostProvider);

    // Check role-based access (Manager/Admin only)
    if (user?.role != 'manager' && user?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Miscellaneous Costs'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Access Restricted',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Only Managers and Admins can access miscellaneous costs',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Miscellaneous Costs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/miscellaneous/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Cost Type Filter
                      ...MiscellaneousCost.costTypes.map((costType) {
                        final isSelected = _selectedCostType == costType;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(MiscellaneousCost.costTypeLabels[costType] ?? costType),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCostType = selected ? costType : null;
                              });
                              _performSearch();
                            },
                            backgroundColor: Colors.white,
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.primary,
                          ),
                        );
                      }),
                      
                      // Clear Filters
                      if (_selectedCostType != null || _searchController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ActionChip(
                            label: const Text('Clear'),
                            onPressed: _clearFilters,
                            backgroundColor: Colors.red.shade50,
                            side: BorderSide(color: Colors.red.shade200),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Search Results Info
                if (_searchController.text.isNotEmpty || _selectedCostType != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Filtered results: ${miscState.miscellaneousCosts.length} items',
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
            child: miscState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : miscState.error != null
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
                              miscState.error!,
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
                    : miscState.miscellaneousCosts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No Miscellaneous Costs',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchController.text.isNotEmpty || _selectedCostType != null
                                      ? 'No costs match your search criteria'
                                      : 'Start by adding your first miscellaneous cost',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => context.push('/miscellaneous/add'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Miscellaneous Cost'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshData,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: miscState.miscellaneousCosts.length,
                              itemBuilder: (context, index) {
                                final cost = miscState.miscellaneousCosts[index];
                                return _buildCostCard(cost);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostCard(MiscellaneousCost cost) {
    final costTypeColor = Color(int.parse(cost.costTypeColor.replaceFirst('#', '0xFF')));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/miscellaneous/${cost.id}/detail'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Cost Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: costTypeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: costTypeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      cost.costTypeLabel,
                      style: TextStyle(
                        color: costTypeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Amount
                  Text(
                    cost.formattedAmount,
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
                          cost.operationName,
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
                                cost.party,
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
                              DateFormat('dd MMM yyyy').format(DateTime.parse(cost.date)),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        
                        // Bill Number (if available)
                        if (cost.billNo != null && cost.billNo!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.receipt, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Bill: ${cost.billNo}',
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
                        'Qty: ${cost.formattedQuantity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Rate: ${cost.formattedRate}',
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
              if (cost.remarks != null && cost.remarks!.isNotEmpty) ...[
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
                          cost.remarks!,
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
                    'By ${cost.createdByName ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(cost.createdAt)),
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