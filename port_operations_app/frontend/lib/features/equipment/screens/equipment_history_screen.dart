import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/equipment_service.dart';
import '../models/equipment_model.dart';
import '../../../core/services/api_service.dart';
import '../../auth/auth_service.dart';

class EquipmentHistoryScreen extends ConsumerStatefulWidget {
  const EquipmentHistoryScreen({super.key});

  @override
  ConsumerState<EquipmentHistoryScreen> createState() => _EquipmentHistoryScreenState();
}

class _EquipmentHistoryScreenState extends ConsumerState<EquipmentHistoryScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _filterOptions = ['all', 'completed', 'today', 'week', 'month'];

  @override
  void initState() {
    super.initState();
    // Load equipment history when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(equipmentHistoryProvider.notifier).loadEquipmentHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(equipmentHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment History'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: historyState.equipment.isNotEmpty ? _exportData : null,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: historyState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(historyState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by vehicle number, operation, or party...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => _applyFilters(),
          ),
          
          const SizedBox(height: 12),
          
          // Quick filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getFilterLabel(filter)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = selected ? filter : 'all';
                      });
                      _applyFilters();
                    },
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(EquipmentHistoryState state) {
    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    if (state.equipment.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Summary stats
        _buildSummaryStats(state.equipment),
        
        // Equipment list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(equipmentHistoryProvider.notifier).loadEquipmentHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.equipment.length,
              itemBuilder: (context, index) {
                final equipment = state.equipment[index];
                return _buildEquipmentCard(equipment);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStats(List<Equipment> equipment) {
    final totalHours = equipment.fold<double>(0, (sum, eq) {
      if (eq.durationHours != null) {
        return sum + (double.tryParse(eq.durationHours!) ?? 0);
      }
      return sum;
    });

    final uniqueOperations = equipment.map((e) => e.operationName).toSet().length;
    final uniqueVehicles = equipment.map((e) => e.vehicleNumber).toSet().length;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Entries', '${equipment.length}', Icons.list_alt),
          _buildStatItem('Total Hours', '${totalHours.toStringAsFixed(1)}h', Icons.access_time),
          _buildStatItem('Operations', '$uniqueOperations', Icons.work),
          _buildStatItem('Vehicles', '$uniqueVehicles', Icons.local_shipping),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentCard(Equipment equipment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment.displayTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        equipment.operationName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: equipment.isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    equipment.isCompleted ? 'Completed' : 'Running',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: equipment.isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Details grid
            Row(
              children: [
                Expanded(
                  child: _buildDetailColumn([
                    _buildDetailRow('Work Type', equipment.workTypeName, Icons.build),
                    _buildDetailRow('Party', equipment.partyName, Icons.business),
                  ]),
                ),
                Expanded(
                  child: _buildDetailColumn([
                    _buildDetailRow('Started', equipment.formattedStartTime, Icons.play_arrow),
                    _buildDetailRow('Duration', equipment.formattedDuration, Icons.timer),
                  ]),
                ),
              ],
            ),
            
            if (equipment.comments != null && equipment.comments!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Comments: ${equipment.comments}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            
            // Footer info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Started by: ${equipment.createdByName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (equipment.endedByName != null)
                  Text(
                    'Ended by: ${equipment.endedByName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(equipmentHistoryProvider.notifier).loadEquipmentHistory(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Equipment History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Equipment history will appear here once equipment is completed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/equipment/start'),
            icon: const Icon(Icons.add),
            label: const Text('Start Equipment'),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All';
      case 'completed':
        return 'Completed';
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      default:
        return filter;
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    ref.read(equipmentHistoryProvider.notifier).filterEquipment(
      searchQuery: query,
      filter: _selectedFilter,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> _showFilterDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advanced Filters'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date range
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setDialogState(() {
                            _startDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _startDate != null
                            ? DateFormat('dd/MM/yyyy').format(_startDate!)
                            : 'Start Date',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setDialogState(() {
                            _endDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _endDate != null
                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                            : 'End Date',
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Clear filters button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Date Filters'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyFilters();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    // TODO: Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

// Equipment History State Management
class EquipmentHistoryState {
  final List<Equipment> equipment;
  final List<Equipment> filteredEquipment;
  final bool isLoading;
  final String? error;

  const EquipmentHistoryState({
    this.equipment = const [],
    this.filteredEquipment = const [],
    this.isLoading = false,
    this.error,
  });

  EquipmentHistoryState copyWith({
    List<Equipment>? equipment,
    List<Equipment>? filteredEquipment,
    bool? isLoading,
    String? error,
  }) {
    return EquipmentHistoryState(
      equipment: equipment ?? this.equipment,
      filteredEquipment: filteredEquipment ?? this.filteredEquipment,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EquipmentHistoryNotifier extends StateNotifier<EquipmentHistoryState> {
  final ApiService _apiService;

  EquipmentHistoryNotifier(this._apiService) : super(const EquipmentHistoryState());

  Future<void> loadEquipmentHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.get('/operations/equipment/');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is Map ? data['results'] ?? data : data;
        final equipment = results.map((json) => Equipment.fromJson(json)).toList();
        
        state = state.copyWith(
          equipment: equipment,
          filteredEquipment: equipment,
          isLoading: false,
        );
      } else {
        throw Exception('Failed to load equipment history');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load equipment history: ${e.toString()}',
      );
    }
  }

  void filterEquipment({
    String? searchQuery,
    String? filter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var filtered = List<Equipment>.from(state.equipment);

    // Apply search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered.where((equipment) {
        return equipment.vehicleNumber.toLowerCase().contains(searchQuery) ||
               equipment.operationName.toLowerCase().contains(searchQuery) ||
               equipment.partyName.toLowerCase().contains(searchQuery) ||
               equipment.vehicleTypeName.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // Apply status filter
    if (filter != null) {
      switch (filter) {
        case 'completed':
          filtered = filtered.where((e) => e.isCompleted).toList();
          break;
        case 'today':
          final today = DateTime.now();
          filtered = filtered.where((e) {
            final equipmentDate = DateTime.parse(e.createdAt);
            return equipmentDate.year == today.year &&
                   equipmentDate.month == today.month &&
                   equipmentDate.day == today.day;
          }).toList();
          break;
        case 'week':
          final weekAgo = DateTime.now().subtract(const Duration(days: 7));
          filtered = filtered.where((e) {
            final equipmentDate = DateTime.parse(e.createdAt);
            return equipmentDate.isAfter(weekAgo);
          }).toList();
          break;
        case 'month':
          final monthAgo = DateTime.now().subtract(const Duration(days: 30));
          filtered = filtered.where((e) {
            final equipmentDate = DateTime.parse(e.createdAt);
            return equipmentDate.isAfter(monthAgo);
          }).toList();
          break;
      }
    }

    // Apply date range filter
    if (startDate != null || endDate != null) {
      filtered = filtered.where((equipment) {
        final equipmentDate = DateTime.parse(equipment.createdAt);
        final startCheck = startDate == null || equipmentDate.isAfter(startDate.subtract(const Duration(days: 1)));
        final endCheck = endDate == null || equipmentDate.isBefore(endDate.add(const Duration(days: 1)));
        return startCheck && endCheck;
      }).toList();
    }

    state = state.copyWith(filteredEquipment: filtered);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final equipmentHistoryProvider = StateNotifierProvider<EquipmentHistoryNotifier, EquipmentHistoryState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return EquipmentHistoryNotifier(apiService);
}); 