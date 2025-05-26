import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/models/rate_master_model.dart';
import '../../../shared/models/contractor_model.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../rate_master_service.dart';
import '../../contractors/contractor_service.dart';
import '../../auth/auth_service.dart';

class RateMasterListScreen extends ConsumerStatefulWidget {
  const RateMasterListScreen({super.key});

  @override
  ConsumerState<RateMasterListScreen> createState() => _RateMasterListScreenState();
}

class _RateMasterListScreenState extends ConsumerState<RateMasterListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLabourType;
  int? _selectedContractor;
  List<RateMaster> _filteredRateMasters = [];
  List<RateMaster> _allRateMasters = [];
  List<ContractorMaster> _contractors = [];

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

  void _loadData() async {
    // Load contractors
    try {
      final contractorService = ref.read(contractorServiceProvider);
      final contractors = await contractorService.getContractors();
      setState(() {
        _contractors = contractors;
      });
    } catch (e) {
      // Handle error
    }
    
    // Load rate masters
    ref.read(rateMasterProvider.notifier).loadRateMasters();
  }

  void _filterRateMasters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRateMasters = _allRateMasters.where((rateMaster) {
        final matchesSearch = query.isEmpty || _matchesSearchQuery(rateMaster, query);
        final matchesType = _selectedLabourType == null || rateMaster.labourType == _selectedLabourType;
        final matchesContractor = _selectedContractor == null || rateMaster.contractor == _selectedContractor;
        return matchesSearch && matchesType && matchesContractor;
      }).toList();
    });
  }

  bool _matchesSearchQuery(RateMaster rateMaster, String query) {
    return (rateMaster.contractorName?.toLowerCase().contains(query) == true) ||
        (rateMaster.labourTypeDisplay?.toLowerCase().contains(query) == true) ||
        rateMaster.rate.toString().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final rateMasterState = ref.watch(rateMasterProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Only admins and managers can access rate master
    if (!user.isAdmin && !user.isManager) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rate Master'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'You do not have permission to access this page',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Master'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(rateMasterProvider.notifier).loadRateMasters(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRateDialog(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: rateMasterState.when(
              data: (rateMasters) {
                _allRateMasters = rateMasters;
                if (_filteredRateMasters.isEmpty && _searchController.text.isEmpty && _selectedLabourType == null && _selectedContractor == null) {
                  _filteredRateMasters = rateMasters;
                }
                return _buildRateMasterList(_filteredRateMasters);
              },
              loading: () => const LoadingWidget(),
              error: (error, stack) => AppErrorWidget(
                message: error.toString(),
                onRetry: () => ref.read(rateMasterProvider.notifier).loadRateMasters(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search rates...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _filterRateMasters(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLabourType,
                    decoration: const InputDecoration(
                      labelText: 'Labour Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...RateMaster.labourTypeChoices.map((choice) =>
                        DropdownMenuItem<String>(
                          value: choice['value'],
                          child: Text(choice['label']!),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLabourType = value;
                      });
                      _filterRateMasters();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedContractor,
                    decoration: const InputDecoration(
                      labelText: 'Contractor',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('All Contractors'),
                      ),
                      ..._contractors.map((contractor) =>
                        DropdownMenuItem<int>(
                          value: contractor.id,
                          child: Text(contractor.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedContractor = value;
                      });
                      _filterRateMasters();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateMasterList(List<RateMaster> rateMasters) {
    if (rateMasters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MdiIcons.currencyUsd,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'No rates found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add rates for contractors to enable automatic rate calculation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddRateDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Rate'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(rateMasterProvider.notifier).loadRateMasters(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rateMasters.length,
        itemBuilder: (context, index) {
          final rateMaster = rateMasters[index];
          return _buildRateMasterCard(rateMaster);
        },
      ),
    );
  }

  Widget _buildRateMasterCard(RateMaster rateMaster) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLabourTypeColor(rateMaster.labourType),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rateMaster.labourTypeDisplay ?? rateMaster.labourType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditRateDialog(rateMaster);
                        break;
                      case 'delete':
                        _showDeleteDialog(rateMaster);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rateMaster.contractorName ?? 'Unknown Contractor',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rate per unit',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '₹${NumberFormat('#,##0.00').format(rateMaster.rate)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            if (rateMaster.updatedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last updated: ${DateFormat('MMM dd, yyyy').format(rateMaster.updatedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getLabourTypeColor(String labourType) {
    switch (labourType) {
      case 'casual':
        return AppColors.info;
      case 'tonnes':
        return AppColors.warning;
      case 'fixed':
        return AppColors.success;
      default:
        return AppColors.grey400;
    }
  }

  void _showAddRateDialog() {
    _showRateDialog();
  }

  void _showEditRateDialog(RateMaster rateMaster) {
    _showRateDialog(rateMaster: rateMaster);
  }

  void _showRateDialog({RateMaster? rateMaster}) {
    final isEditing = rateMaster != null;
    int? selectedContractor = rateMaster?.contractor;
    String? selectedLabourType = rateMaster?.labourType;
    final rateController = TextEditingController(text: rateMaster?.rate.toString() ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Rate' : 'Add New Rate'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedContractor,
                      decoration: const InputDecoration(
                        labelText: 'Contractor',
                        border: OutlineInputBorder(),
                      ),
                      items: _contractors.map((contractor) =>
                        DropdownMenuItem<int>(
                          value: contractor.id,
                          child: Text(contractor.name),
                        ),
                      ).toList(),
                      onChanged: isEditing ? null : (value) {
                        setDialogState(() {
                          selectedContractor = value;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a contractor' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedLabourType,
                      decoration: const InputDecoration(
                        labelText: 'Labour Type',
                        border: OutlineInputBorder(),
                      ),
                      items: RateMaster.labourTypeChoices.map((choice) =>
                        DropdownMenuItem<String>(
                          value: choice['value'],
                          child: Text(choice['label']!),
                        ),
                      ).toList(),
                      onChanged: isEditing ? null : (value) {
                        setDialogState(() {
                          selectedLabourType = value;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a labour type' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: rateController,
                      decoration: const InputDecoration(
                        labelText: 'Rate (₹)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Rate must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedContractor == null || selectedLabourType == null || rateController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    final rate = double.tryParse(rateController.text);
                    if (rate == null || rate <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid rate'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    try {
                      final newRateMaster = RateMaster(
                        id: rateMaster?.id,
                        contractor: selectedContractor!,
                        labourType: selectedLabourType!,
                        rate: rate,
                      );

                      if (isEditing) {
                        await ref.read(rateMasterProvider.notifier).updateRateMaster(
                          rateMaster.id!,
                          newRateMaster,
                        );
                      } else {
                        await ref.read(rateMasterProvider.notifier).createRateMaster(newRateMaster);
                      }

                      Navigator.of(dialogContext).pop();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'Rate updated successfully' : 'Rate added successfully'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to ${isEditing ? 'update' : 'add'} rate: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(RateMaster rateMaster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rate'),
        content: Text(
          'Are you sure you want to delete the rate for ${rateMaster.contractorName} - ${rateMaster.labourTypeDisplay}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(rateMasterProvider.notifier).deleteRateMaster(rateMaster.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rate deleted successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete rate: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 