import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/user_model.dart';
import '../equipment/models/equipment_model.dart';
import '../../shared/models/cargo_operation_model.dart';
import '../../shared/models/revenue_stream_model.dart';
import '../auth/auth_service.dart';
import '../equipment/services/equipment_service.dart';
import '../operations/operations_service.dart';
import '../revenue/services/revenue_service.dart';
import '../labour/labour_service.dart';
import '../../shared/models/labour_cost_model.dart';
import '../../shared/widgets/app_drawer.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final Set<int> _expandedEquipmentCards = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    // Load different data based on user role
    if (user.role == 'manager' || user.role == 'supervisor') {
      // Load equipment and operations data
      ref.read(equipmentManagementProvider.notifier).loadRunningEquipment();
      ref.read(operationsManagementProvider.notifier).loadOperations();
      
      // Load labour costs for supervisor
      if (user.role == 'supervisor') {
        ref.read(labourCostProvider.notifier).loadLabourCosts();
      }
    }
    
    if (user.role == 'admin') {
      // Load comprehensive data for admin
      ref.read(equipmentManagementProvider.notifier).loadRunningEquipment();
      ref.read(operationsManagementProvider.notifier).loadOperations();
      ref.read(revenueStreamProvider.notifier).loadRevenueStreams();
    }

    if (user.role == 'manager' || user.role == 'admin') {
      // Load financial data
      ref.read(revenueStreamProvider.notifier).loadRevenueStreams();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${user.roleDisplayName} Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context, user),
              const SizedBox(height: 16),
              ..._buildRoleSpecificContent(context, user, ref),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRoleSpecificContent(BuildContext context, User user, WidgetRef ref) {
    switch (user.role) {
      case 'admin':
        return _buildAdminDashboard(context, ref);
      case 'manager':
        return _buildManagerDashboard(context, ref);
      case 'supervisor':
        return _buildSupervisorDashboard(context, ref);
      default:
        return _buildOperatorDashboard(context, ref);
    }
  }

  List<Widget> _buildAdminDashboard(BuildContext context, WidgetRef ref) {
    return [
      _buildSystemStatsSection(context, ref),
      const SizedBox(height: 16),
      _buildFinancialOverviewSection(context, ref),
      const SizedBox(height: 16),
      _buildRunningEquipmentSection(context, ref, showStopButtons: false),
      const SizedBox(height: 16),
      _buildAdminQuickActions(context),
      const SizedBox(height: 16),
      _buildRecentActivitiesSection(context, ref),
    ];
  }

  List<Widget> _buildManagerDashboard(BuildContext context, WidgetRef ref) {
    return [
      _buildOperationsStatsSection(context, ref),
      const SizedBox(height: 16),
      _buildRunningEquipmentSection(context, ref, showStopButtons: true),
      const SizedBox(height: 16),
      _buildFinancialSummarySection(context, ref),
      const SizedBox(height: 16),
      _buildManagerQuickActions(context),
      const SizedBox(height: 16),
      _buildTodaysOperationsSection(context, ref),
    ];
  }

  List<Widget> _buildSupervisorDashboard(BuildContext context, WidgetRef ref) {
    return [
      _buildRunningEquipmentSection(context, ref, showStopButtons: true),
      const SizedBox(height: 16),
      _buildLabourDetailsByShiftsSection(context, ref),
      const SizedBox(height: 16),
      _buildSupervisorQuickActions(context),
      const SizedBox(height: 16),
      _buildEquipmentAlertsSection(context, ref),
    ];
  }

  List<Widget> _buildOperatorDashboard(BuildContext context, WidgetRef ref) {
    return [
      _buildOperatorStatsSection(context, ref),
      const SizedBox(height: 16),
      _buildOperatorQuickActions(context),
      const SizedBox(height: 16),
      _buildMyEquipmentSection(context, ref),
    ];
  }

  Widget _buildWelcomeCard(BuildContext context, User user) {
    final now = DateTime.now();
    final timeOfDay = now.hour < 12 ? 'Morning' : now.hour < 17 ? 'Afternoon' : 'Evening';
    
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.white.withValues(alpha: 0.2),
                  child: Text(
                    user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good $timeOfDay!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        user.fullName.isNotEmpty ? user.fullName : user.username,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.roleDisplayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _getRoleIcon(user.role),
                  color: AppColors.white.withValues(alpha: 0.7),
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(now),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Equipment Cards Section (Most Important for Manager/Supervisor)
  Widget _buildRunningEquipmentSection(BuildContext context, WidgetRef ref, {bool showStopButtons = false}) {
    final equipmentState = ref.watch(equipmentManagementProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
              'Running Equipment',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
            ),
            if (showStopButtons)
              TextButton.icon(
                onPressed: () => context.push('/equipment'),
                icon: const Icon(Icons.visibility),
                label: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (equipmentState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (equipmentState.runningEquipment.isEmpty)
          _buildEmptyEquipmentCard()
        else
          // Single column with vertically scrollable equipment cards
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4, // Dynamic height based on screen size
            ),
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              itemCount: equipmentState.runningEquipment.length,
              itemBuilder: (context, index) {
                final equipment = equipmentState.runningEquipment[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildFullWidthEquipmentCard(context, ref, equipment, showStopButtons),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFullWidthEquipmentCard(BuildContext context, WidgetRef ref, Equipment equipment, bool showStopButton) {
    final startTime = DateTime.tryParse(equipment.startTime);
    final duration = startTime != null ? DateTime.now().difference(startTime) : null;
    final contractType = equipment.contractType.toLowerCase();
    final isExpanded = _expandedEquipmentCards.contains(equipment.id);
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedEquipmentCards.remove(equipment.id);
            } else {
              _expandedEquipmentCards.add(equipment.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Vehicle Number with time info
              Row(
                children: [
                  Expanded(
                    child: Text(
                      equipment.vehicleNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (duration != null)
                    _buildTimeInfo(equipment, contractType, duration),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status badges and action button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getContractColor(contractType),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      contractType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (contractType == 'shift') ...[
                    const SizedBox(width: 8),
                    _buildShiftTimeToEndWarning(equipment),
                  ],
                  const Spacer(),
                  if (showStopButton)
                    ElevatedButton(
                      onPressed: () => _showStopEquipmentDialog(context, ref, equipment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Stop',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Equipment details in two columns
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: Operation and Work Type
                  Expanded(
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.business, equipment.operationName, AppColors.primary),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.build, equipment.workTypeName, AppColors.secondary),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right column: Party and Started by
                  Expanded(
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person, equipment.partyName, Colors.grey[600]!),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.account_circle, equipment.createdByName, Colors.grey[500]!),
                      ],
                    ),
                  ),
                ],
              ),
            
            // Expanded details section
            if (isExpanded) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildEquipmentDetails(context, equipment),
            ],
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildContractDot(String contractType) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getContractColor(contractType),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getContractColor(String contractType) {
    switch (contractType.toLowerCase()) {
      case 'hourly':
        return Colors.blue.shade600;
      case 'shift':
        return Colors.orange.shade600;
      case 'tonnes':
        return Colors.purple.shade600;
      case 'fixed':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildTimeInfo(Equipment equipment, String contractType, Duration duration) {
    switch (contractType) {
      case 'hourly':
        final hours = equipment.currentRunningHours;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            '${hours.toStringAsFixed(1)}h',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        );
      case 'shift':
        final shiftsRun = equipment.currentShiftsRun;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Text(
            '${shiftsRun.toString().replaceAll('.0', '')} Shifts',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        );
      case 'tonnes':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Text(
            'Qty Req',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.purple.shade700,
            ),
          ),
        );
      case 'fixed':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Text(
            'Fixed',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            '${duration.inHours}h ${duration.inMinutes % 60}m',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        );
    }
  }



  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleNumberWidget(BuildContext context, String vehicleNumber) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 16, // Slightly smaller to fit better
      color: Colors.black87,
    );

    // Show the full vehicle number without dots
    return Tooltip(
      message: vehicleNumber,
      child: Text(
        vehicleNumber,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis, // Changed back to ellipsis for better readability
      ),
    );
  }

  Widget _buildEquipmentDetails(BuildContext context, Equipment equipment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Equipment Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Work Type', equipment.workTypeName, Icons.build),
        _buildDetailRow('Party', equipment.partyName, Icons.business),
        _buildDetailRow('Contract', equipment.contractType.toUpperCase(), Icons.assignment),
        _buildDetailRow('Started', equipment.formattedStartTime, Icons.access_time),
        _buildDetailRow('Started By', equipment.createdByName, Icons.person),
        
        const SizedBox(height: 12),
        _buildContractSpecificInfo(equipment),
      ],
    );
  }



  Widget _buildShiftTimeToEndWarning(Equipment equipment) {
    final timeToEnd = equipment.timeToEndShift;
    
    // Determine urgency based on time to end
    MaterialColor warningColor;
    String message;
    
    if (timeToEnd == '0h 0m') {
      warningColor = Colors.red;
      message = 'ENDED';
    } else {
      // Extract hours from timeToEnd (e.g., "2h 30m")
      final parts = timeToEnd.split(' ');
      final hours = int.tryParse(parts[0].replaceAll('h', '')) ?? 0;
      final minutes = int.tryParse(parts.length > 1 ? parts[1].replaceAll('m', '') : '0') ?? 0;
      final totalMinutes = hours * 60 + minutes;
      
      if (totalMinutes <= 60) {
        warningColor = Colors.orange;
        message = timeToEnd;
      } else {
        warningColor = Colors.green;
        message = timeToEnd;
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: warningColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: warningColor.shade700,
        ),
      ),
    );
  }



  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.black54,
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractSpecificInfo(Equipment equipment) {
    final contractType = equipment.contractType.toLowerCase();
    
    switch (contractType) {
      case 'hourly':
        final startTime = DateTime.tryParse(equipment.startTime);
        if (startTime != null) {
          final duration = DateTime.now().difference(startTime);
          final hours = duration.inHours;
          final minutes = duration.inMinutes % 60;
          
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Hourly Contract',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Hours: ${hours}h ${minutes}m',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          );
        }
        break;
      case 'shift':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Shift Contract - In Progress',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
        );
      case 'tonnes':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.scale, size: 16, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              Text(
                'Tonnes Contract - Quantity Required',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
        );
      case 'fixed':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Fixed Contract - Ready to End',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }

  String _formatStartTime(String startTime) {
    try {
      final dateTime = DateTime.parse(startTime);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return startTime;
    }
  }

  // Updated stop equipment dialog with proper fields
  Future<void> _showStopEquipmentDialog(BuildContext context, WidgetRef ref, Equipment equipment) async {
    final endTimeController = TextEditingController(
      text: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
    );
    final commentsController = TextEditingController();
    final quantityController = TextEditingController();
    DateTime selectedEndTime = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Stop ${equipment.vehicleNumber}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Equipment summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Equipment Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Operation: ${equipment.operationName}'),
                      Text('Work Type: ${equipment.workTypeName}'),
                      Text('Party: ${equipment.partyName}'),
                      Text('Contract: ${equipment.contractType.toUpperCase()}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // End Time
                const Text(
                  'End Time',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: endTimeController,
                  decoration: const InputDecoration(
                    hintText: 'Select end time',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedEndTime,
                      firstDate: DateTime.parse(equipment.startTime),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedEndTime),
                      );
                      if (time != null) {
                        selectedEndTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                        endTimeController.text = DateFormat('dd/MM/yyyy HH:mm').format(selectedEndTime);
                        setDialogState(() {});
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Quantity (only for tonnes contract)
                if (equipment.contractType.toLowerCase() == 'tonnes') ...[
                  const Text(
                    'Quantity (Tonnes)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      hintText: 'Enter quantity in tonnes',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                ],

                // Comments
                const Text(
                  'Comments (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: commentsController,
                  decoration: const InputDecoration(
                    hintText: 'Add any comments...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.comment),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate quantity for tonnes contract
                if (equipment.contractType.toLowerCase() == 'tonnes') {
                  final quantity = double.tryParse(quantityController.text.trim());
                  if (quantity == null || quantity <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid quantity'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Stop Equipment'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      String? quantity;
      if (equipment.contractType.toLowerCase() == 'tonnes') {
        quantity = quantityController.text.trim();
      }
      
      await _endEquipment(
        context,
        ref,
        equipment.id,
        selectedEndTime,
        commentsController.text.trim().isNotEmpty ? commentsController.text.trim() : null,
        quantity,
      );
    }
  }

  // Updated end equipment method
  Future<void> _endEquipment(BuildContext context, WidgetRef ref, int equipmentId, DateTime endTime, String? comments, String? quantity) async {
    try {
      final success = await ref.read(equipmentManagementProvider.notifier).endEquipment(
        equipmentId: equipmentId,
        endTime: endTime,
        comments: comments,
        quantity: quantity,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment stopped successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the equipment list
        ref.read(equipmentManagementProvider.notifier).loadRunningEquipment();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to stop equipment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEmptyEquipmentCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: 200,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MdiIcons.crane,
              size: 56,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'No Equipment Running',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start equipment to track operations',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // System Stats for Admin
  Widget _buildSystemStatsSection(BuildContext context, WidgetRef ref) {
    final operationsState = ref.watch(operationsManagementProvider);
    final equipmentState = ref.watch(equipmentManagementProvider);
    final revenueState = ref.watch(revenueStreamProvider);
    
    final totalRevenue = revenueState.revenueStreams.fold<double>(
      0.0, (sum, stream) => sum + (double.tryParse(stream.amount ?? '0') ?? 0.0)
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.0, // Increased aspect ratio to give more width
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  'Total Operations',
                  '${operationsState.operations.length}',
                  Icons.business,
                  AppColors.primary,
                ),
                _buildStatCard(
                  'Running Equipment',
                  '${equipmentState.runningEquipment.length}',
                  MdiIcons.crane,
                  AppColors.warning,
                ),
                _buildStatCard(
                  'Total Revenue',
                  '₹${NumberFormat('#,##,###').format(totalRevenue)}',
                  Icons.currency_rupee,
                  AppColors.success,
                ),
                _buildStatCard(
                  'Revenue Streams',
                  '${revenueState.revenueStreams.length}',
                  Icons.trending_up,
                  AppColors.info,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Operations Stats for Manager
  Widget _buildOperationsStatsSection(BuildContext context, WidgetRef ref) {
    final operationsState = ref.watch(operationsManagementProvider);
    final stats = operationsState.operationsStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operations Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.0, // Increased aspect ratio
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  'Total Operations',
                  '${stats['total']}',
                  Icons.business,
                  AppColors.primary,
                ),
                _buildStatCard(
                  'Ongoing',
                  '${stats['ongoing']}',
                  Icons.play_circle,
                  AppColors.warning,
                ),
                _buildStatCard(
                  'Pending',
                  '${stats['pending']}',
                  Icons.pending,
                  AppColors.info,
                ),
                _buildStatCard(
                  'Completed',
                  '${stats['completed']}',
                  Icons.check_circle,
                  AppColors.success,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8), // Reduced padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24), // Reduced icon size
            const SizedBox(height: 4), // Reduced spacing
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 10, // Reduced font size
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Financial Overview for Admin
  Widget _buildFinancialOverviewSection(BuildContext context, WidgetRef ref) {
    final revenueState = ref.watch(revenueStreamProvider);
    
    final totalRevenue = revenueState.revenueStreams.fold<double>(
      0.0, (sum, stream) => sum + (double.tryParse(stream.amount ?? '0') ?? 0.0)
    );

    return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
        Text(
          'Financial Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
                      children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Revenue',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '₹${NumberFormat('#,##,###').format(totalRevenue)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'From ${revenueState.revenueStreams.length} revenue streams',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                        Icon(
                  Icons.trending_up,
                  color: AppColors.success,
                  size: 48,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Financial Summary for Manager
  Widget _buildFinancialSummarySection(BuildContext context, WidgetRef ref) {
    final revenueState = ref.watch(revenueStreamProvider);
    
    final totalRevenue = revenueState.revenueStreams.fold<double>(
      0.0, (sum, stream) => sum + (double.tryParse(stream.amount ?? '0') ?? 0.0)
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                        Text(
          'Financial Summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Revenue',
                '₹${NumberFormat('#,##,###').format(totalRevenue)}',
                Icons.currency_rupee,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Revenue Streams',
                '${revenueState.revenueStreams.length}',
                Icons.trending_up,
                AppColors.info,
                          ),
                        ),
                      ],
                    ),
      ],
    );
  }

  // Today's Operations
  Widget _buildTodaysOperationsSection(BuildContext context, WidgetRef ref) {
    final operationsState = ref.watch(operationsManagementProvider);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final todaysOperations = operationsState.operations.where((op) {
      return op.date == today;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
                    Text(
              'Today\'s Operations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/operations'),
              child: const Text('View All'),
                    ),
                  ],
                ),
        const SizedBox(height: 12),
        if (todaysOperations.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Operations Today',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Schedule operations to track progress',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...todaysOperations.take(3).map((operation) => _buildOperationCard(operation)),
      ],
    );
  }

  Widget _buildOperationCard(CargoOperation operation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(operation.projectStatus).withValues(alpha: 0.1),
          child: Icon(
            _getStatusIcon(operation.projectStatus),
            color: _getStatusColor(operation.projectStatus),
          ),
        ),
        title: Text(operation.operationName),
        subtitle: Text('${operation.partyName} • ${operation.cargoType}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(operation.projectStatus).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            operation.projectStatus.toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(operation.projectStatus),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Quick Actions for different roles
  Widget _buildAdminQuickActions(BuildContext context) {
    return _buildQuickActionsSection(context, 'Admin Actions', [
      _buildActionButton('Manage Users', Icons.people, AppColors.primary, () => context.go('/users')),
      _buildActionButton('View Reports', Icons.analytics, AppColors.success, () => context.go('/reports')),
      _buildActionButton('System Settings', Icons.settings, AppColors.secondary, () => context.go('/settings')),
      _buildActionButton('Financial', Icons.account_balance, AppColors.accent, () => context.go('/financial')),
    ]);
  }

  Widget _buildManagerQuickActions(BuildContext context) {
    return _buildQuickActionsSection(context, 'Quick Actions', [
      _buildActionButton('New Operation', Icons.add_business, AppColors.primary, () => context.go('/operations/new')),
      _buildActionButton('Start Equipment', Icons.play_circle, AppColors.success, () => context.push('/equipment/start')),
      _buildActionButton('Revenue Entry', Icons.currency_rupee, AppColors.accent, () => context.push('/revenue/add')),
      _buildActionButton('Equipment Rates', Icons.build_circle, AppColors.warning, () => context.go('/equipment-rates')),
    ]);
  }

  Widget _buildSupervisorQuickActions(BuildContext context) {
    return _buildQuickActionsSection(context, 'Quick Actions', [
      _buildActionButton('Start Equipment', Icons.play_circle, AppColors.success, () => context.push('/equipment/start')),
      _buildActionButton('Equipment History', Icons.history, AppColors.info, () => context.push('/equipment/history')),
      _buildActionButton('End Equipment', Icons.stop_circle, AppColors.error, () => context.push('/equipment/end')),
      _buildActionButton('Operations', Icons.business, AppColors.primary, () => context.go('/operations')),
    ]);
  }

  Widget _buildOperatorQuickActions(BuildContext context) {
    return _buildQuickActionsSection(context, 'Quick Actions', [
      _buildActionButton('View Wallet', Icons.account_balance_wallet, AppColors.primary, () => context.go('/wallet')),
      _buildActionButton('Submit Expense', Icons.receipt_long, AppColors.warning, () => context.go('/expenses/new')),
      _buildActionButton('Digital Voucher', Icons.camera_alt, AppColors.secondary, () => context.go('/vouchers/new')),
      _buildActionButton('My Equipment', Icons.build, AppColors.info, () => context.go('/equipment/my')),
    ]);
  }

  Widget _buildQuickActionsSection(BuildContext context, String title, List<Widget> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3.0, // Increased aspect ratio for action buttons
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: actions,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced padding
          child: Row(
            children: [
              Icon(icon, color: color, size: 20), // Reduced icon size
              const SizedBox(width: 8), // Reduced spacing
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12, // Reduced font size
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Additional sections for different roles
  Widget _buildOperatorStatsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.0, // Increased aspect ratio
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard('Wallet Balance', '₹0', Icons.account_balance_wallet, AppColors.success),
                _buildStatCard('My Equipment', '0', Icons.build, AppColors.warning),
                _buildStatCard('Pending Expenses', '0', Icons.receipt, AppColors.error),
                _buildStatCard('Today\'s Tasks', '0', Icons.today, AppColors.primary),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMyEquipmentSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Equipment',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.build,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Active Equipment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your assigned equipment will appear here',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentAlertsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Equipment Alerts',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
                ),
                const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.notifications,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Equipment alerts and notifications will appear here',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Recent Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Recent system activities will appear here',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Labour Details by Shifts Section for Supervisor
  Widget _buildLabourDetailsByShiftsSection(BuildContext context, WidgetRef ref) {
    final labourCostState = ref.watch(labourCostProvider);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Labour Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/labour'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        labourCostState.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load labour details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please refresh to try again',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (labourCosts) {
            // Filter for today's labour costs
            final todaysLabourCosts = labourCosts.where((lc) {
              final labourDate = DateFormat('yyyy-MM-dd').format(lc.date);
              return labourDate == today;
            }).toList();
            
            if (todaysLabourCosts.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Labour Records Today',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Labour records for today will appear here',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Group by shifts
            final shiftGroups = _groupLabourByShifts(todaysLabourCosts);
            
            return Column(
              children: [
                _buildShiftSection(context, '1st Shift (7 AM - 3 PM)', shiftGroups['1st_shift'] ?? [], Colors.orange),
                const SizedBox(height: 12),
                _buildShiftSection(context, '2nd Shift (3 PM - 11 PM)', shiftGroups['2nd_shift'] ?? [], Colors.blue),
                const SizedBox(height: 12),
                _buildShiftSection(context, '3rd Shift (11 PM - 7 AM)', shiftGroups['3rd_shift'] ?? [], Colors.purple),
              ],
            );
          },
        ),
      ],
    );
  }

  Map<String, List<LabourCost>> _groupLabourByShifts(List<LabourCost> labourCosts) {
    final Map<String, List<LabourCost>> shiftGroups = {
      '1st_shift': [],
      '2nd_shift': [],
      '3rd_shift': [],
    };
    
    for (final labourCost in labourCosts) {
      final shift = labourCost.shift ?? '1st_shift'; // Default to 1st shift if not specified
      if (shiftGroups.containsKey(shift)) {
        shiftGroups[shift]!.add(labourCost);
      }
    }
    
    return shiftGroups;
  }

  Widget _buildShiftSection(BuildContext context, String shiftTitle, List<LabourCost> labourCosts, Color shiftColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: shiftColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    shiftTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: shiftColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: shiftColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${labourCosts.length} Records',
                    style: TextStyle(
                      color: shiftColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (labourCosts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No labour records for this shift',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ...labourCosts.map((labourCost) => _buildLabourCostCard(labourCost)),
          ],
        ),
      ),
    );
  }

  Widget _buildLabourCostCard(LabourCost labourCost) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  labourCost.contractorName ?? 'Unknown Contractor',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getLabourTypeColor(labourCost.labourType),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  labourCost.labourTypeDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.business, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  labourCost.operationName ?? 'Unknown Operation',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.work, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                labourCost.workTypeDisplay,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.group, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${labourCost.labourCountTonnage} ${_getLabourCountUnit(labourCost.labourType)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.person, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Ordered by: ${labourCost.createdByName ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLabourTypeColor(String labourType) {
    switch (labourType) {
      case 'casual':
        return Colors.blue;
      case 'skilled':
        return Colors.green;
      case 'operator':
        return Colors.orange;
      case 'supervisor':
        return Colors.purple;
      case 'tonnes':
        return Colors.red;
      case 'fixed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getLabourCountUnit(String labourType) {
    switch (labourType) {
      case 'casual':
        return 'Workers';
      case 'tonnes':
        return 'Tonnes';
      case 'fixed':
        return 'Job';
      default:
        return 'Workers';
    }
  }

  // Helper methods
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.business_center;
      case 'supervisor':
        return Icons.supervisor_account;
      case 'operator':
        return Icons.build;
      case 'accountant':
        return Icons.account_balance;
      default:
        return Icons.person;
    }
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
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'ongoing':
        return Icons.play_circle;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
} 