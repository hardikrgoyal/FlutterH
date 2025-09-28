import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';

// Models for list management
class ListType {
  final int id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final int itemsCount;

  ListType({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.itemsCount,
  });

  factory ListType.fromJson(Map<String, dynamic> json) {
    return ListType(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      description: json['description'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      itemsCount: json['items_count'],
    );
  }
}

class ListItem {
  final int id;
  final int listType;
  final String? listTypeName;
  final String? listTypeCode;
  final String name;
  final String? code;
  final String? description;
  final int sortOrder;
  final bool isActive;
  final int createdBy;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  ListItem({
    required this.id,
    required this.listType,
    this.listTypeName,
    this.listTypeCode,
    required this.name,
    this.code,
    this.description,
    required this.sortOrder,
    required this.isActive,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      id: json['id'],
      listType: json['list_type'],
      listTypeName: json['list_type_name'],
      listTypeCode: json['list_type_code'],
      name: json['name'],
      code: json['code'],
      description: json['description'],
      sortOrder: json['sort_order'],
      isActive: json['is_active'],
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'list_type': listType,
      'name': name,
      'code': code,
      'description': description,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}

class SimpleListItem {
  final int id;
  final String name;
  final String? code;
  final int sortOrder;

  SimpleListItem({
    required this.id,
    required this.name,
    this.code,
    required this.sortOrder,
  });

  factory SimpleListItem.fromJson(Map<String, dynamic> json) {
    return SimpleListItem(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      sortOrder: json['sort_order'],
    );
  }
}

class ListData {
  final String listType;
  final List<SimpleListItem> items;

  ListData({
    required this.listType,
    required this.items,
  });

  factory ListData.fromJson(Map<String, dynamic> json) {
    return ListData(
      listType: json['list_type'],
      items: (json['items'] as List)
          .map((item) => SimpleListItem.fromJson(item))
          .toList(),
    );
  }
}

class AllListsData {
  final int id;
  final String name;
  final String code;
  final String? description;
  final int itemsCount;
  final List<SimpleListItem> items;

  AllListsData({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.itemsCount,
    required this.items,
  });

  factory AllListsData.fromJson(Map<String, dynamic> json) {
    return AllListsData(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      description: json['description'],
      itemsCount: json['items_count'],
      items: (json['items'] as List)
          .map((item) => SimpleListItem.fromJson(item))
          .toList(),
    );
  }
}

// Audit log model for list items
class ListItemAuditLog {
  final int id;
  final String listTypeCode;
  final String listTypeName;
  final int itemId;
  final String itemName;
  final String action;
  final int? performedBy;
  final String? performedByName;
  final String? performedByEmail;
  final Map<String, dynamic>? changes;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  ListItemAuditLog({
    required this.id,
    required this.listTypeCode,
    required this.listTypeName,
    required this.itemId,
    required this.itemName,
    required this.action,
    this.performedBy,
    this.performedByName,
    this.performedByEmail,
    this.changes,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory ListItemAuditLog.fromJson(Map<String, dynamic> json) {
    return ListItemAuditLog(
      id: json['id'],
      listTypeCode: json['list_type_code'],
      listTypeName: json['list_type_name'],
      itemId: json['item_id'],
      itemName: json['item_name'],
      action: json['action'],
      performedBy: json['performed_by'],
      performedByName: json['performed_by_name'],
      performedByEmail: json['performed_by_email'],
      changes: json['changes'],
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get actionDisplay {
    switch (action) {
      case 'created':
        return 'Created';
      case 'updated':
        return 'Updated';
      case 'deleted':
        return 'Deleted';
      case 'activated':
        return 'Activated';
      case 'deactivated':
        return 'Deactivated';
      default:
        return action.toUpperCase();
    }
  }
}

// State classes
class ListManagementState {
  final List<AllListsData> allLists;
  final Map<String, ListData> cachedListData;
  final Map<String, List<ListItemAuditLog>> auditLogsByItem;
  final bool isLoading;
  final String? error;

  const ListManagementState({
    this.allLists = const [],
    this.cachedListData = const {},
    this.auditLogsByItem = const {},
    this.isLoading = false,
    this.error,
  });

  ListManagementState copyWith({
    List<AllListsData>? allLists,
    Map<String, ListData>? cachedListData,
    Map<String, List<ListItemAuditLog>>? auditLogsByItem,
    bool? isLoading,
    String? error,
  }) {
    return ListManagementState(
      allLists: allLists ?? this.allLists,
      cachedListData: cachedListData ?? this.cachedListData,
      auditLogsByItem: auditLogsByItem ?? this.auditLogsByItem,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<ListItemAuditLog> getAuditLogsForItem(String listTypeCode, int itemId) {
    return auditLogsByItem['${listTypeCode}_$itemId'] ?? [];
  }
}

// List Management Notifier
class ListManagementNotifier extends StateNotifier<ListManagementState> {
  final ApiService _apiService;

  ListManagementNotifier(this._apiService) : super(const ListManagementState());

  // Load all lists for management screen
  Future<void> loadAllLists() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/lists/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final allLists = data.map((json) => AllListsData.fromJson(json)).toList();

        state = state.copyWith(
          allLists: allLists,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: 'Failed to load lists',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load lists: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  // Get list data by type code (for dropdowns)
  Future<ListData?> getListData(String listTypeCode) async {
    // Check cache first
    if (state.cachedListData.containsKey(listTypeCode)) {
      return state.cachedListData[listTypeCode];
    }

    try {
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/lists/$listTypeCode/');

      if (response.statusCode == 200) {
        final listData = ListData.fromJson(response.data);
        
        // Cache the data
        final updatedCache = Map<String, ListData>.from(state.cachedListData);
        updatedCache[listTypeCode] = listData;
        
        state = state.copyWith(cachedListData: updatedCache);
        return listData;
      }
    } catch (e) {
      print('Error loading list data for $listTypeCode: $e');
    }
    
    return null;
  }

  // Add new list item
  Future<bool> addListItem(ListItem item) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/list-items/',
        data: item.toJson(),
      );

      if (response.statusCode == 201) {
        // Refresh all lists and clear cache
        await loadAllLists();
        state = state.copyWith(cachedListData: {});
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to add list item: ${e.toString()}');
    }
    return false;
  }

  // Update list item
  Future<bool> updateListItem(int id, ListItem item) async {
    try {
      final response = await _apiService.put(
        '${AppConstants.operationsBaseUrl}/list-items/$id/',
        data: item.toJson(),
      );

      if (response.statusCode == 200) {
        // Refresh all lists and clear cache
        await loadAllLists();
        state = state.copyWith(cachedListData: {});
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update list item: ${e.toString()}');
    }
    return false;
  }

  // Delete list item
  Future<bool> deleteListItem(int id) async {
    try {
      final response = await _apiService.delete('${AppConstants.operationsBaseUrl}/list-items/$id/');

      if (response.statusCode == 204) {
        // Refresh all lists and clear cache
        await loadAllLists();
        state = state.copyWith(cachedListData: {});
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete list item: ${e.toString()}');
    }
    return false;
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Load audit logs for a list item
  Future<void> loadAuditLogsForItem(String listTypeCode, int itemId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.operationsBaseUrl}/list-item-audit-logs/by_item/?list_type_code=$listTypeCode&item_id=$itemId'
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is Map ? data['results'] ?? data : data;
        
        final auditLogs = results.map((json) => ListItemAuditLog.fromJson(json)).toList();
        
        final updatedAuditLogs = Map<String, List<ListItemAuditLog>>.from(state.auditLogsByItem);
        updatedAuditLogs['${listTypeCode}_$itemId'] = auditLogs;

        state = state.copyWith(auditLogsByItem: updatedAuditLogs);
      }
    } catch (e) {
      // Silently fail for audit logs - not critical
      print('Failed to load audit logs for item: $e');
    }
  }

  // Clear cache for a specific list type
  void clearCacheForListType(String listTypeCode) {
    final updatedCache = Map<String, ListData>.from(state.cachedListData);
    updatedCache.remove(listTypeCode);
    state = state.copyWith(cachedListData: updatedCache);
  }
}

// Providers
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final listManagementProvider = StateNotifierProvider<ListManagementNotifier, ListManagementState>((ref) {
  return ListManagementNotifier(ref.watch(apiServiceProvider));
});

// Helper provider for getting list data by type
final listDataProvider = FutureProvider.family<ListData?, String>((ref, listTypeCode) async {
  final notifier = ref.read(listManagementProvider.notifier);
  return await notifier.getListData(listTypeCode);
}); 