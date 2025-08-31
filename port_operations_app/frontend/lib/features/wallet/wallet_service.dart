import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../shared/models/user_model.dart';

class WalletService {
  final ApiService _apiService;

  WalletService(this._apiService);

  // Get wallet balance
  Future<WalletBalance> getWalletBalance() async {
    try {
      final response = await _apiService.get('/financial/wallet/balance/');
      return WalletBalance.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get wallet balance: $e');
    }
  }

  // Get wallet transactions
  Future<List<WalletTransaction>> getWalletTransactions() async {
    try {
      final response = await _apiService.get('/financial/wallet/transactions/');
      
      // Handle different response structures
      dynamic data = response.data;
      List<dynamic> transactionList;
      
      if (data is List) {
        transactionList = data;
      } else if (data is Map && data.containsKey('results')) {
        transactionList = data['results'] as List;
      } else if (data is Map) {
        // If it's a map but no 'results' key, return empty list
        transactionList = [];
      } else {
        transactionList = [];
      }
      
      return transactionList
          .map((json) => WalletTransaction.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get wallet transactions: $e');
    }
  }

  // Get wallet holders (for accountants)
  Future<List<WalletHolder>> getWalletHolders() async {
    try {
      final response = await _apiService.get('/financial/wallet/holders/');
      return (response.data['wallet_holders'] as List)
          .map((json) => WalletHolder.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get wallet holders: $e');
    }
  }

  // Top up wallet
  Future<void> topUpWallet({
    required String userId,
    required double amount,
    required String paymentMethod,
    String? referenceNumber,
    String? remarks,
  }) async {
    try {
      final data = {
        'user': int.parse(userId),
        'amount': amount.toString(),
        'payment_method': paymentMethod,
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'reference_number': referenceNumber,
        if (remarks != null && remarks.isNotEmpty)
          'remarks': remarks,
      };

      await _apiService.post('/financial/wallet-topups/', data: data);
    } catch (e) {
      throw Exception('Failed to top up wallet: $e');
    }
  }

  // Create port expense
  Future<void> createPortExpense({
    required DateTime dateTime,
    required String vehicle,
    required String vehicleNumber,
    required String gateNo,
    required String description,
    double? cisfAmount,
    double? kptAmount,
    double? customsAmount,
    int? roadTaxDays,
    double? otherCharges,
    String? photoPath,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'date_time': dateTime.toIso8601String(),
        'vehicle': vehicle,
        'vehicle_number': vehicleNumber,
        'gate_no': gateNo,
        'description': description,
        if (cisfAmount != null) 'cisf_amount': cisfAmount,
        if (kptAmount != null) 'kpt_amount': kptAmount,
        if (customsAmount != null) 'customs_amount': customsAmount,
        if (roadTaxDays != null) 'road_tax_days': roadTaxDays,
        if (otherCharges != null) 'other_charges': otherCharges,
        if (photoPath != null) 'photo': await MultipartFile.fromFile(photoPath),
      });

      await _apiService.post('/financial/port-expenses/', data: formData);
    } catch (e) {
      throw Exception('Failed to create port expense: $e');
    }
  }

  // Create digital voucher
  Future<void> createDigitalVoucher({
    required DateTime dateTime,
    required String expenseCategory,
    required double amount,
    required String billPhotoPath,
    String? remarks,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'date_time': dateTime.toIso8601String(),
        'expense_category': expenseCategory,
        'amount': amount,
        'bill_photo': await MultipartFile.fromFile(billPhotoPath),
        if (remarks != null) 'remarks': remarks,
      });

      await _apiService.post('/financial/digital-vouchers/', data: formData);
    } catch (e) {
      throw Exception('Failed to create digital voucher: $e');
    }
  }

  // Get approval workflow
  Future<ApprovalWorkflow> getApprovalWorkflow() async {
    try {
      final response = await _apiService.get('/financial/approvals/workflow/');
      return ApprovalWorkflow.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get approval workflow: $e');
    }
  }

  // Approve/reject individual item
  Future<void> approveItem({
    required String itemType, // 'expense' or 'voucher'
    required int itemId,
    required String action, // 'approve', 'reject', 'finalize', 'log'
    String? comments,
    String? tallyReference,
  }) async {
    try {
      final endpoint = itemType == 'expense' 
          ? '/financial/expenses/approve/$itemId/'
          : '/financial/vouchers/approve/$itemId/';
      
      await _apiService.patch(endpoint, data: {
        'action': action,
        if (comments != null) 'comments': comments,
        if (tallyReference != null) 'tally_reference': tallyReference,
      });
    } catch (e) {
      throw Exception('Failed to approve item: $e');
    }
  }

  // Bulk approval
  Future<BulkApprovalResult> bulkApproval({
    required String itemType,
    required List<int> itemIds,
    required String action,
    String? comments,
    String? tallyReference,
  }) async {
    try {
      final response = await _apiService.post('/financial/approvals/bulk/', data: {
        'type': itemType,
        'ids': itemIds,
        'action': action,
        if (comments != null) 'comments': comments,
        if (tallyReference != null) 'tally_reference': tallyReference,
      });
      
      return BulkApprovalResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to bulk approve: $e');
    }
  }

  // Get submitted expenses for current user
  Future<List<PortExpenseStatus>> getMyExpenses() async {
    try {
      final response = await _apiService.get('/financial/port-expenses/');
      
      dynamic data = response.data;
      List<dynamic> expenseList;
      
      if (data is List) {
        expenseList = data;
      } else if (data is Map && data.containsKey('results')) {
        expenseList = data['results'] as List;
      } else {
        expenseList = [];
      }
      
      return expenseList
          .map((json) => PortExpenseStatus.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get expenses: $e');
    }
  }

  // Get submitted vouchers for current user
  Future<List<VoucherStatus>> getMyVouchers() async {
    try {
      final response = await _apiService.get('/financial/digital-vouchers/');
      
      dynamic data = response.data;
      List<dynamic> voucherList;
      
      if (data is List) {
        voucherList = data;
      } else if (data is Map && data.containsKey('results')) {
        voucherList = data['results'] as List;
      } else {
        voucherList = [];
      }
      
      return voucherList
          .map((json) => VoucherStatus.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get vouchers: $e');
    }
  }

  // Get all expenses for approval (managers, admins, accountants)
  Future<List<PortExpenseStatus>> getAllExpenses() async {
    try {
      final response = await _apiService.get('/financial/port-expenses/all/');
      
      dynamic data = response.data;
      List<dynamic> expenseList;
      
      if (data is List) {
        expenseList = data;
      } else if (data is Map && data.containsKey('results')) {
        expenseList = data['results'] as List;
      } else {
        expenseList = [];
      }
      
      return expenseList
          .map((json) => PortExpenseStatus.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all expenses: $e');
    }
  }

  // Get all vouchers for approval (admins, accountants)
  Future<List<VoucherStatus>> getAllVouchers() async {
    try {
      final response = await _apiService.get('/financial/digital-vouchers/all/');
      
      dynamic data = response.data;
      List<dynamic> voucherList;
      
      if (data is List) {
        voucherList = data;
      } else if (data is Map && data.containsKey('results')) {
        voucherList = data['results'] as List;
      } else {
        voucherList = [];
      }
      
      return voucherList
          .map((json) => VoucherStatus.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all vouchers: $e');
    }
  }

  // Approve/reject/finalize expense
  Future<void> approveExpense(int expenseId, String action, String comments) async {
    try {
      await _apiService.patch(
        '/financial/port-expenses/$expenseId/approve/',
        data: {
          'action': action,
          'comments': comments,
        },
      );
    } catch (e) {
      throw Exception('Failed to $action expense: $e');
    }
  }

  // Approve/decline/log voucher
  Future<void> approveVoucher(int voucherId, String action, String comments, {String? tallyReference}) async {
    try {
      final data = {
        'action': action,
        'comments': comments,
      };
      
      if (tallyReference != null && tallyReference.isNotEmpty) {
        data['tally_reference'] = tallyReference;
      }
      
      await _apiService.patch(
        '/financial/digital-vouchers/$voucherId/approve/',
        data: data,
      );
    } catch (e) {
      throw Exception('Failed to $action voucher: $e');
    }
  }

  // Download Excel reports
  Future<List<int>> downloadPortExpensesExcel({DateTime? week}) async {
    try {
      final queryParams = week != null ? {'week': week.toIso8601String().split('T')[0]} : null;
      final response = await _apiService.download('/financial/reports/port-expenses/excel/', queryParameters: queryParams);
      return response.data!;
    } catch (e) {
      throw Exception('Failed to download port expenses report: $e');
    }
  }

  Future<List<int>> downloadDigitalVouchersExcel({DateTime? week}) async {
    try {
      final queryParams = week != null ? {'week': week.toIso8601String().split('T')[0]} : null;
      final response = await _apiService.download('/financial/reports/digital-vouchers/excel/', queryParameters: queryParams);
      return response.data!;
    } catch (e) {
      throw Exception('Failed to download digital vouchers report: $e');
    }
  }
}

// Data models
class WalletBalance {
  final int userId;
  final String username;
  final double balance;
  final DateTime lastUpdated;

  WalletBalance({
    required this.userId,
    required this.username,
    required this.balance,
    required this.lastUpdated,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      userId: json['user_id'],
      username: json['username'],
      balance: double.parse(json['balance'].toString()),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

class WalletTransaction {
  final int id;
  final String userName;
  final String action;
  final double amount;
  final String reference;
  final String? referenceId;
  final String? approvedByName;
  final String? description;
  final double balanceAfter;
  final DateTime date;

  WalletTransaction({
    required this.id,
    required this.userName,
    required this.action,
    required this.amount,
    required this.reference,
    this.referenceId,
    this.approvedByName,
    this.description,
    required this.balanceAfter,
    required this.date,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      userName: json['user_name'],
      action: json['action'],
      amount: double.parse(json['amount'].toString()),
      reference: json['reference'],
      referenceId: json['reference_id'],
      approvedByName: json['approved_by_name'],
      description: json['description'],
      balanceAfter: double.parse(json['balance_after'].toString()),
      date: DateTime.parse(json['date']),
    );
  }

  bool get isCredit => action == 'credit';
}

class WalletHolder {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String role;
  final double currentBalance;

  WalletHolder({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.currentBalance,
  });

  factory WalletHolder.fromJson(Map<String, dynamic> json) {
    return WalletHolder(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: json['role'],
      currentBalance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

class ApprovalWorkflow {
  final List<ApprovalItem> pendingExpenses;
  final List<ApprovalItem> pendingVouchers;
  final String userRole;
  final ApprovalCounts approvalCounts;

  ApprovalWorkflow({
    required this.pendingExpenses,
    required this.pendingVouchers,
    required this.userRole,
    required this.approvalCounts,
  });

  factory ApprovalWorkflow.fromJson(Map<String, dynamic> json) {
    return ApprovalWorkflow(
      pendingExpenses: (json['pending_expenses'] as List)
          .map((item) => ApprovalItem.fromJson(item))
          .toList(),
      pendingVouchers: (json['pending_vouchers'] as List)
          .map((item) => ApprovalItem.fromJson(item))
          .toList(),
      userRole: json['user_role'],
      approvalCounts: ApprovalCounts.fromJson(json['approval_counts']),
    );
  }
}

class ApprovalItem {
  final int id;
  final String title;
  final double amount;
  final DateTime dateTime;
  final String userName;
  final String? reviewedByName;
  final DateTime createdAt;

  ApprovalItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.dateTime,
    required this.userName,
    this.reviewedByName,
    required this.createdAt,
  });

  factory ApprovalItem.fromJson(Map<String, dynamic> json) {
    // Handle both expense and voucher formats
    String title = '';
    double amount = 0.0;
    
    if (json.containsKey('vehicle')) {
      // Port expense
      title = '${json['vehicle']} ${json['vehicle_number']}';
      amount = double.parse(json['total_amount'].toString());
    } else if (json.containsKey('expense_category')) {
      // Digital voucher
      title = json['expense_category'];
      amount = double.parse(json['amount'].toString());
    }

    return ApprovalItem(
      id: json['id'],
      title: title,
      amount: amount,
      dateTime: DateTime.parse(json['date_time']),
      userName: json['user__username'],
      reviewedByName: json['reviewed_by__username'] ?? json['approved_by__username'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ApprovalCounts {
  final int expenses;
  final int vouchers;
  final int total;

  ApprovalCounts({
    required this.expenses,
    required this.vouchers,
    required this.total,
  });

  factory ApprovalCounts.fromJson(Map<String, dynamic> json) {
    return ApprovalCounts(
      expenses: json['expenses'],
      vouchers: json['vouchers'],
      total: json['total'],
    );
  }
}

class BulkApprovalResult {
  final List<Map<String, dynamic>> results;
  final int processed;
  final int successful;

  BulkApprovalResult({
    required this.results,
    required this.processed,
    required this.successful,
  });

  factory BulkApprovalResult.fromJson(Map<String, dynamic> json) {
    return BulkApprovalResult(
      results: List<Map<String, dynamic>>.from(json['results']),
      processed: json['processed'],
      successful: json['successful'],
    );
  }
}

class PortExpenseStatus {
  final int id;
  final String vehicle;
  final String vehicleNumber;
  final String gateNo;
  final double totalAmount;
  final String status;
  final DateTime dateTime;
  final String? reviewedByName;
  final String? approvedByName;
  final String? reviewComments;
  final DateTime createdAt;

  PortExpenseStatus({
    required this.id,
    required this.vehicle,
    required this.vehicleNumber,
    required this.gateNo,
    required this.totalAmount,
    required this.status,
    required this.dateTime,
    this.reviewedByName,
    this.approvedByName,
    this.reviewComments,
    required this.createdAt,
  });

  factory PortExpenseStatus.fromJson(Map<String, dynamic> json) {
    return PortExpenseStatus(
      id: json['id'],
      vehicle: json['vehicle'],
      vehicleNumber: json['vehicle_number'],
      gateNo: json['gate_no'],
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'],
      dateTime: DateTime.parse(json['date_time']),
      reviewedByName: json['reviewed_by_name'],
      approvedByName: json['approved_by_name'],
      reviewComments: json['review_comments'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class VoucherStatus {
  final int id;
  final String expenseCategory;
  final double amount;
  final String status;
  final DateTime dateTime;
  final String? remarks;
  final String? billPhotoUrl;
  final String userName;
  final String? approvedByName;
  final String? loggedByName;
  final String? approvalComments;
  final String? tallyReference;
  final DateTime createdAt;

  VoucherStatus({
    required this.id,
    required this.expenseCategory,
    required this.amount,
    required this.status,
    required this.dateTime,
    this.remarks,
    this.billPhotoUrl,
    required this.userName,
    this.approvedByName,
    this.loggedByName,
    this.approvalComments,
    this.tallyReference,
    required this.createdAt,
  });

  factory VoucherStatus.fromJson(Map<String, dynamic> json) {
    return VoucherStatus(
      id: json['id'],
      expenseCategory: json['expense_category'],
      amount: double.parse(json['amount'].toString()),
      status: json['status'],
      dateTime: DateTime.parse(json['date_time']),
      remarks: json['remarks'],
      billPhotoUrl: json['bill_photo'],
      userName: json['user_name'] ?? 'Unknown',
      approvedByName: json['approved_by_name'],
      loggedByName: json['logged_by_name'],
      approvalComments: json['approval_comments'],
      tallyReference: json['tally_reference'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
} 