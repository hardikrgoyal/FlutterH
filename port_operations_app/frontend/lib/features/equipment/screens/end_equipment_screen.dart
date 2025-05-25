import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../services/equipment_service.dart';
import '../models/equipment_model.dart';

class EndEquipmentScreen extends ConsumerStatefulWidget {
  const EndEquipmentScreen({super.key});

  @override
  ConsumerState<EndEquipmentScreen> createState() => _EndEquipmentScreenState();
}

class _EndEquipmentScreenState extends ConsumerState<EndEquipmentScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load running equipment when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(equipmentManagementProvider.notifier).loadRunningEquipment();
    });
  }

  @override
  Widget build(BuildContext context) {
    final equipmentState = ref.watch(equipmentManagementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('End Equipment'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(equipmentManagementProvider.notifier).loadRunningEquipment(),
            child: equipmentState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(equipmentState),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(EquipmentManagementState state) {
    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    if (state.runningEquipment.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.runningEquipment.length,
      itemBuilder: (context, index) {
        final equipment = state.runningEquipment[index];
        return _buildEquipmentCard(equipment);
      },
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
            'Error Loading Equipment',
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
            onPressed: () => ref.read(equipmentManagementProvider.notifier).loadRunningEquipment(),
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
            Icons.construction,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Running Equipment',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no equipment currently running.\nStart some equipment to see them here.',
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

  Widget _buildEquipmentCard(Equipment equipment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with vehicle info and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment.displayTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        equipment.operationName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_filled,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Running',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Equipment details
            _buildDetailRow('Work Type', equipment.workTypeName, Icons.build),
            _buildDetailRow('Party', equipment.partyName, Icons.business),
            _buildDetailRow('Contract', equipment.contractType.toUpperCase(), Icons.assignment),
            _buildDetailRow('Started', equipment.formattedStartTime, Icons.access_time),
            _buildDetailRow('Started By', equipment.createdByName, Icons.person),
            
            const SizedBox(height: 20),
            
            // End Equipment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showEndEquipmentDialog(equipment),
                icon: const Icon(Icons.stop_circle),
                label: const Text('End Equipment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEndEquipmentDialog(Equipment equipment) async {
    final endTimeController = TextEditingController(
      text: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
    );
    final commentsController = TextEditingController();
    DateTime selectedEndTime = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('End ${equipment.displayTitle}'),
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
                      Text('Started: ${equipment.formattedStartTime}'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // End time field
                TextField(
                  controller: endTimeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'End Time *',
                    hintText: 'Select end time',
                    prefixIcon: Icon(Icons.access_time),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
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
                        
                        setDialogState(() {
                          endTimeController.text = DateFormat('dd/MM/yyyy HH:mm').format(selectedEndTime);
                        });
                      }
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Comments field
                TextField(
                  controller: commentsController,
                  decoration: const InputDecoration(
                    labelText: 'Comments',
                    hintText: 'Optional comments about the work',
                    prefixIcon: Icon(Icons.comment),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
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
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('End Equipment'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _endEquipment(
        equipment.id,
        selectedEndTime,
        commentsController.text.trim().isNotEmpty ? commentsController.text.trim() : null,
      );
    }
  }

  Future<void> _endEquipment(int equipmentId, DateTime endTime, String? comments) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref.read(equipmentManagementProvider.notifier).endEquipment(
        equipmentId: equipmentId,
        endTime: endTime,
        comments: comments,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment ended successfully!'),
            backgroundColor: Colors.green,
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