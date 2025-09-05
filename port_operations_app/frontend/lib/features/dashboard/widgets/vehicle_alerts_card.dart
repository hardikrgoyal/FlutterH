import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class VehicleAlertsCard extends StatelessWidget {
  final Map<String, dynamic> vehicleAlerts;

  const VehicleAlertsCard({super.key, required this.vehicleAlerts});

  @override
  Widget build(BuildContext context) {
    final expiringSoon = vehicleAlerts['expiring_soon'] as List<dynamic>? ?? [];
    final recentlyExpired = vehicleAlerts['recently_expired'] as List<dynamic>? ?? [];
    final totalExpiringCount = vehicleAlerts['total_expiring_count'] as int? ?? 0;
    final totalExpiredCount = vehicleAlerts['total_expired_count'] as int? ?? 0;

    if (expiringSoon.isEmpty && recentlyExpired.isEmpty) {
      return const SizedBox.shrink(); // Don't show card if no alerts
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.warning),
                const SizedBox(width: 8),
                const Text(
                  'Vehicle Document Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/vehicle-documents'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Expiring Soon Section
            if (expiringSoon.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.warning, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Expiring Soon ($totalExpiringCount)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...expiringSoon.take(3).map((doc) => _buildAlertItem(
                doc['vehicle_number'],
                doc['document_type'],
                'Expires in ${doc['days_until_expiry']} days',
                doc['is_urgent'] ? AppColors.error : AppColors.warning,
              )),
              if (expiringSoon.length > 3)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    '...and ${expiringSoon.length - 3} more',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],

            // Recently Expired Section
            if (recentlyExpired.isNotEmpty) ...[
              if (expiringSoon.isNotEmpty) const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.error, color: AppColors.error, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Recently Expired ($totalExpiredCount)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...recentlyExpired.take(2).map((doc) => _buildAlertItem(
                doc['vehicle_number'],
                doc['document_type'],
                'Expired ${doc['days_since_expiry']} days ago',
                AppColors.error,
              )),
              if (recentlyExpired.length > 2)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    '...and ${recentlyExpired.length - 2} more',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(String vehicleNumber, String documentType, String message, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$vehicleNumber - $documentType',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 