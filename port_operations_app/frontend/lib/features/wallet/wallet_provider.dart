import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import 'wallet_service.dart';

// Wallet service provider
final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService(ApiService());
});

// Wallet balance provider
final walletBalanceProvider = FutureProvider<WalletBalance>((ref) async {
  final walletService = ref.read(walletServiceProvider);
  return await walletService.getWalletBalance();
});

// Wallet transactions provider
final walletTransactionsProvider = FutureProvider<List<WalletTransaction>>((ref) async {
  final walletService = ref.read(walletServiceProvider);
  return await walletService.getWalletTransactions();
});

// Wallet holders provider (for accountants)
final walletHoldersProvider = FutureProvider<List<WalletHolder>>((ref) async {
  final walletService = ref.read(walletServiceProvider);
  return await walletService.getWalletHolders();
});

// Approval workflow provider
final approvalWorkflowProvider = FutureProvider<ApprovalWorkflow>((ref) async {
  final walletService = ref.read(walletServiceProvider);
  return await walletService.getApprovalWorkflow();
});

// Filtered transactions state provider
final transactionFilterProvider = StateProvider<String>((ref) => 'all');

final filteredTransactionsProvider = Provider<AsyncValue<List<WalletTransaction>>>((ref) {
  final transactions = ref.watch(walletTransactionsProvider);
  final filter = ref.watch(transactionFilterProvider);
  
  return transactions.when(
    data: (data) {
      if (filter == 'all') {
        return AsyncValue.data(data);
      }
      final filtered = data.where((tx) => tx.action == filter).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// My expenses provider
final myExpensesProvider = FutureProvider<List<PortExpenseStatus>>((ref) async {
  final walletService = ref.read(walletServiceProvider);
  return await walletService.getMyExpenses();
});

// My vouchers provider
final myVouchersProvider = FutureProvider<List<VoucherStatus>>((ref) async {
  final walletService = ref.read(walletServiceProvider);
  return await walletService.getMyVouchers();
});

// All expenses provider (for approvers)
final allExpensesProvider = FutureProvider<List<PortExpenseStatus>>((ref) async {
  final walletService = ref.read(walletServiceProvider);
  return await walletService.getAllExpenses();
});

// All vouchers provider (for approvers)
final allVouchersProvider = FutureProvider<List<VoucherStatus>>((ref) async {
  final walletService = ref.read(walletServiceProvider);
  return await walletService.getAllVouchers();
});

// Refresh providers
extension WalletProviderRefresh on WidgetRef {
  void refreshWalletData() {
    invalidate(walletBalanceProvider);
    invalidate(walletTransactionsProvider);
    invalidate(approvalWorkflowProvider);
    invalidate(myExpensesProvider);
    invalidate(myVouchersProvider);
    invalidate(allExpensesProvider);
    invalidate(allVouchersProvider);
  }
} 