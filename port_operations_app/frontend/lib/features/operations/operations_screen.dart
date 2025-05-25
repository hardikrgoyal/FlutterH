import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/models/cargo_operation_model.dart';
import '../auth/auth_service.dart';
import 'operations_service.dart';

class OperationsScreen extends ConsumerStatefulWidget {
  const OperationsScreen({super.key});

  @override
  ConsumerState<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends ConsumerState<OperationsScreen> {
  final List<String> _filters = ['all', 'pending', 'ongoing', 'completed'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final operationsState = ref.watch(operationsManagementProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(operationsManagementProvider.notifier).refreshOperations();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: user.isManager || user.isAdmin
          ? FloatingActionButton(
              onPressed: () => context.go('/operations/new'),
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.read(operationsManagementProvider.notifier).refreshOperations(),
        child: Column(
          children: [
            _buildStatusCards(operationsState.operationsStats),
            _buildFilterChips(operationsState.selectedStatus),
            Expanded(
              child: _buildOperationsList(operationsState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCards(Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              'Total',
              '${stats['total'] ?? 0}',
              AppColors.primary,
              MdiIcons.shipWheel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatusCard(
              'Pending',
              '${stats['pending'] ?? 0}',
              AppColors.warning,
              Icons.pending,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatusCard(
              'Ongoing',
              '${stats['ongoing'] ?? 0}',
              AppColors.info,
              Icons.play_circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatusCard(
              'Completed',
              '${stats['completed'] ?? 0}',
              AppColors.success,
              Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String count, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(String selectedFilter) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = selectedFilter == filter;
          
          return FilterChip(
            label: Text(filter.toUpperCase()),
            selected: isSelected,
            onSelected: (selected) {
              ref.read(operationsManagementProvider.notifier).updateStatusFilter(filter);
            },
          );
        },
      ),
    );
  }

  Widget _buildOperationsList(OperationsManagementState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading operations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(operationsManagementProvider.notifier).refreshOperations();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final operations = state.filteredOperations;
    
    if (operations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MdiIcons.shipWheel,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No operations found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new operation to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: operations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final operation = operations[index];
        return _buildOperationCard(operation);
      },
    );
  }

  Widget _buildOperationCard(CargoOperation operation) {
    final status = operation.projectStatus;
    final statusColor = _getStatusColor(status);

    return Card(
      child: InkWell(
        onTap: () {
          // TODO: Navigate to operation details
          // context.go('/operations/${operation.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          operation.operationName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Party: ${operation.partyName}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      operation.displayStatus.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _getCargoIcon(operation.cargoType),
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    operation.displayCargoType,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.scale,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    operation.formattedWeight,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.inventory,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    operation.packaging,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Date: ${operation.formattedDate}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (operation.createdByName != null)
                    Text(
                      'By: ${operation.createdByName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
              if (operation.remarks != null && operation.remarks!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    operation.remarks!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'ongoing':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getCargoIcon(String cargoType) {
    switch (cargoType) {
      case 'container':
        return MdiIcons.cube;
      case 'bulk':
        return MdiIcons.grain;
      case 'breakbulk':
        return MdiIcons.packageVariant;
      case 'project':
        return MdiIcons.crane;
      case 'others':
        return MdiIcons.truck;
      default:
        return MdiIcons.truck;
    }
  }

  void _showSearchDialog() {
    final operationsNotifier = ref.read(operationsManagementProvider.notifier);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Operations'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search by operation name, party, or packaging',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            operationsNotifier.updateSearchQuery(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              operationsNotifier.updateSearchQuery('');
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 