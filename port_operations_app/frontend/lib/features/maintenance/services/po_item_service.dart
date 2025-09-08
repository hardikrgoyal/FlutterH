
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../auth/auth_service.dart';

class POItem {
  final int? id;
  final int purchaseOrder;
  final String itemName;
  final double quantity;
  final double rate;
  final double amount;
  final int? createdBy;
  final String? createdByName;
  final String? createdAt;
  final String? updatedAt;

  POItem({
    this.id,
    required this.purchaseOrder,
    required this.itemName,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  factory POItem.fromJson(Map<String, dynamic> json) {
    return POItem(
      id: json['id'],
      purchaseOrder: json['purchase_order'],
      itemName: json['item_name'] ?? '',
      quantity: _parseDouble(json['quantity']),
      rate: _parseDouble(json['rate']),
      amount: _parseDouble(json['amount']),
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'purchase_order': purchaseOrder,
      'item_name': itemName,
      'quantity': quantity,
      'rate': rate,
    };
  }
}

class POItemService {
  final ApiService _apiService;

  POItemService(this._apiService);

  /// Get all items for a specific purchase order
  Future<List<POItem>> getPOItems(int purchaseOrderId) async {
    try {
      final response = await _apiService.get('/operations/po-items/', queryParameters: {
        'purchase_order': purchaseOrderId.toString(),
      });

      if (response.data['results'] != null) {
        return (response.data['results'] as List)
            .map((json) => POItem.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load PO items: $e');
    }
  }

  /// Create a new PO item
  Future<POItem> createPOItem(POItem item) async {
    try {
      final response = await _apiService.post('/operations/po-items/', data: item.toJson());
      return POItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create PO item: $e');
    }
  }

  /// Update an existing PO item
  Future<POItem> updatePOItem(int itemId, POItem item) async {
    try {
      final response = await _apiService.put('/operations/po-items/$itemId/', data: item.toJson());
      return POItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update PO item: $e');
    }
  }

  /// Delete a PO item
  Future<void> deletePOItem(int itemId) async {
    try {
      await _apiService.delete('/operations/po-items/$itemId/');
    } catch (e) {
      throw Exception('Failed to delete PO item: $e');
    }
  }

  /// Create multiple PO items in a batch
  Future<List<POItem>> createPOItemsBatch(List<POItem> items) async {
    try {
      final List<POItem> createdItems = [];
      
      for (final item in items) {
        final createdItem = await createPOItem(item);
        createdItems.add(createdItem);
      }
      
      return createdItems;
    } catch (e) {
      throw Exception('Failed to create PO items batch: $e');
    }
  }

  /// Update multiple PO items in a batch
  Future<List<POItem>> updatePOItemsBatch(List<POItem> items) async {
    try {
      final List<POItem> updatedItems = [];
      
      for (final item in items) {
        if (item.id != null) {
          final updatedItem = await updatePOItem(item.id!, item);
          updatedItems.add(updatedItem);
        }
      }
      
      return updatedItems;
    } catch (e) {
      throw Exception('Failed to update PO items batch: $e');
    }
  }
}

// Riverpod provider for POItemService
final poItemServiceProvider = Provider<POItemService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return POItemService(apiService);
});

// Provider for fetching PO items by purchase order ID
final poItemsProvider = FutureProvider.family<List<POItem>, int>((ref, purchaseOrderId) async {
  final service = ref.read(poItemServiceProvider);
  return service.getPOItems(purchaseOrderId);
}); 