import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_model.dart';
import '../services/finance_service.dart';
import 'auth_provider.dart';

// Finance State
class FinanceState {
  final List<FinanceModel> finances;
  final bool isLoading;
  final String? error;
  final int selectedMonth;
  final int selectedYear;
  final double totalIncome;
  final double totalExpense;
  final double balance;

  const FinanceState({
    this.finances = const [],
    this.isLoading = false,
    this.error,
    required this.selectedMonth,
    required this.selectedYear,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.balance = 0,
  });

  FinanceState copyWith({
    List<FinanceModel>? finances,
    bool? isLoading,
    String? error,
    int? selectedMonth,
    int? selectedYear,
    double? totalIncome,
    double? totalExpense,
    double? balance,
  }) {
    return FinanceState(
      finances: finances ?? this.finances,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      balance: balance ?? this.balance,
    );
  }

  List<FinanceModel> get incomeList =>
      finances.where((f) => f.isIncome).toList();
  List<FinanceModel> get expenseList =>
      finances.where((f) => f.isExpense).toList();
}

// Finance Notifier
class FinanceNotifier extends StateNotifier<FinanceState> {
  final FinanceService _financeService;
  final String userId;

  FinanceNotifier(this._financeService, this.userId)
      : super(FinanceState(
          selectedMonth: DateTime.now().month,
          selectedYear: DateTime.now().year,
        )) {
    loadFinances();
  }

  Future<void> loadFinances({int? month, int? year}) async {
    final m = month ?? state.selectedMonth;
    final y = year ?? state.selectedYear;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final finances = await _financeService.getFinances(
        userId: userId,
        month: m,
        year: y,
      );

      double totalIncome = 0;
      double totalExpense = 0;
      for (final f in finances) {
        if (f.isIncome) {
          totalIncome += f.amount;
        } else {
          totalExpense += f.amount;
        }
      }

      state = state.copyWith(
        finances: finances,
        isLoading: false,
        selectedMonth: m,
        selectedYear: y,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: totalIncome - totalExpense,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data keuangan.',
      );
    }
  }

  void changeMonth(int month, int year) {
    loadFinances(month: month, year: year);
  }

  Future<bool> createFinance({
    required String type,
    required String category,
    required double amount,
    String note = '',
    DateTime? date,
  }) async {
    try {
      final finance = await _financeService.createFinance(
        userId: userId,
        type: type,
        category: category,
        amount: amount,
        note: note,
        date: date,
      );

      // Only add to list if in selected month
      final selectedDate = date ?? DateTime.now();
      if (selectedDate.month == state.selectedMonth &&
          selectedDate.year == state.selectedYear) {
        final updated = [finance, ...state.finances];
        final totalIncome = type == 'income'
            ? state.totalIncome + amount
            : state.totalIncome;
        final totalExpense = type == 'expense'
            ? state.totalExpense + amount
            : state.totalExpense;
        state = state.copyWith(
          finances: updated,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          balance: totalIncome - totalExpense,
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal menambah transaksi.');
      return false;
    }
  }

  Future<bool> updateFinance({
    required String financeId,
    String? type,
    String? category,
    double? amount,
    String? note,
    DateTime? date,
  }) async {
    try {
      final updated = await _financeService.updateFinance(
        financeId: financeId,
        type: type,
        category: category,
        amount: amount,
        note: note,
        date: date,
      );
      final finances = state.finances
          .map((f) => f.id == financeId ? updated : f)
          .toList();

      // Recalculate totals
      double totalIncome = 0;
      double totalExpense = 0;
      for (final f in finances) {
        if (f.isIncome) totalIncome += f.amount;
        else totalExpense += f.amount;
      }

      state = state.copyWith(
        finances: finances,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: totalIncome - totalExpense,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal mengupdate transaksi.');
      return false;
    }
  }

  Future<bool> deleteFinance(String financeId) async {
    try {
      await _financeService.deleteFinance(financeId);
      final finances = state.finances.where((f) => f.id != financeId).toList();

      double totalIncome = 0;
      double totalExpense = 0;
      for (final f in finances) {
        if (f.isIncome) totalIncome += f.amount;
        else totalExpense += f.amount;
      }

      state = state.copyWith(
        finances: finances,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: totalIncome - totalExpense,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal menghapus transaksi.');
      return false;
    }
  }
}

// Providers
final financeServiceProvider =
    Provider<FinanceService>((ref) => FinanceService());

final financeProvider =
    StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  return FinanceNotifier(ref.read(financeServiceProvider), userId);
});

// Total balance provider (all time)
final totalBalanceProvider = FutureProvider<double>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  if (userId.isEmpty) return 0;
  return ref.read(financeServiceProvider).getTotalBalance(userId: userId);
});
