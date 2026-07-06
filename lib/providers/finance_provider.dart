import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_model.dart';
import '../services/finance_service.dart';
import '../core/constants/app_constants.dart';
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

  /// Validates amount and category
  bool _validateInput({
    required double amount,
    required String type,
    required String category,
  }) {
    // Validate amount
    if (amount <= 0) {
      state = state.copyWith(error: 'Jumlah harus lebih besar dari 0');
      return false;
    }

    // Validate category based on type
    final validCategories = type == 'income'
        ? AppConstants.incomeCategories
        : AppConstants.expenseCategories;

    if (!validCategories.contains(category)) {
      state = state.copyWith(error: 'Kategori tidak valid');
      return false;
    }

    return true;
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

      if (!mounted) return;
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
      final errorMessage = _parseErrorMessage(e);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  void changeMonth(int month, int year) {
    loadFinances(month: month, year: year);
  }

  // ── Private error handler ───────────────────────────────────────────────
  String _parseErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('403')) {
      return 'Anda tidak memiliki akses. Silakan login ulang.';
    } else if (errorStr.contains('409')) {
      return 'Data sudah diubah oleh pengguna lain. Silakan refresh.';
    } else if (errorStr.contains('500')) {
      return 'Server error. Coba lagi nanti.';
    } else if (errorStr.contains('401')) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    } else if (errorStr.contains('404')) {
      return 'Data tidak ditemukan.';
    }

    return 'Gagal memproses permintaan.';
  }

  Future<bool> createFinance({
    required String type,
    required String category,
    required double amount,
    String note = '',
    DateTime? date,
  }) async {
    // Validate input
    if (!_validateInput(
      amount: amount,
      type: type,
      category: category,
    )) {
      return false;
    }

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
        if (!mounted) return false;
        state = state.copyWith(
          finances: updated,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          balance: totalIncome - totalExpense,
        );
      }
      return true;
    } catch (e) {
      final errorMessage = _parseErrorMessage(e);
      if (!mounted) return false;
      state = state.copyWith(error: errorMessage);
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
    // Validate input if provided
    if (amount != null && amount <= 0) {
      state = state.copyWith(error: 'Jumlah harus lebih besar dari 0');
      return false;
    }

    // Get the current finance to validate category against correct type
    final currentFinance = state.finances
        .cast<FinanceModel?>()
        .firstWhere(
          (f) => f?.id == financeId,
          orElse: () => null,
        );

    if (currentFinance == null) {
      state = state.copyWith(error: 'Transaksi tidak ditemukan');
      return false;
    }

    final financeType = type ?? currentFinance.type;
    if (category != null) {
      final validCategories = financeType == 'income'
          ? AppConstants.incomeCategories
          : AppConstants.expenseCategories;

      if (!validCategories.contains(category)) {
        state = state.copyWith(error: 'Kategori tidak valid');
        return false;
      }
    }

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
        if (f.isIncome) {
          totalIncome += f.amount;
        } else {
          totalExpense += f.amount;
        }
      }

      if (!mounted) return false;
      state = state.copyWith(
        finances: finances,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: totalIncome - totalExpense,
      );
      return true;
    } catch (e) {
      final errorMessage = _parseErrorMessage(e);
      if (!mounted) return false;
      state = state.copyWith(error: errorMessage);
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
        if (f.isIncome) {
          totalIncome += f.amount;
        } else {
          totalExpense += f.amount;
        }
      }

      if (!mounted) return false;
      state = state.copyWith(
        finances: finances,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: totalIncome - totalExpense,
      );
      return true;
    } catch (e) {
      final errorMessage = _parseErrorMessage(e);
      if (!mounted) return false;
      state = state.copyWith(error: errorMessage);
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
