import 'package:pocketbase/pocketbase.dart';
import '../core/constants/app_constants.dart';
import '../models/finance_model.dart';
import 'pocketbase_service.dart';

class FinanceService {
  final PocketBase _pb = PocketBaseService.instance.pb;

  // Get all finances for user
  Future<List<FinanceModel>> getFinances({
    required String userId,
    String? type,
    int? month,
    int? year,
  }) async {
    String filter = 'user = "$userId"';
    if (type != null && type.isNotEmpty) {
      filter += ' && type = "$type"';
    }
    if (month != null && year != null) {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);
      filter +=
          ' && date >= "${start.toIso8601String()}" && date < "${end.toIso8601String()}"';
    }

    final result = await _pb.collection(AppConstants.colFinances).getList(
      filter: filter,
      sort: '-date',
      perPage: 500,
      headers: PocketBaseService.instance.authHeaders(),
    );

    return result.items
        .map((r) => FinanceModel.fromJson({...r.toJson(), ...r.data}))
        .toList();
  }

  // Get single finance record
  Future<FinanceModel> getFinance(String financeId) async {
    final record = await _pb.collection(AppConstants.colFinances).getOne(
      financeId,
      headers: PocketBaseService.instance.authHeaders(),
    );
    return FinanceModel.fromJson({...record.toJson(), ...record.data});
  }

  // Create finance record
  Future<FinanceModel> createFinance({
    required String userId,
    required String type,
    required String category,
    required double amount,
    String note = '',
    DateTime? date,
  }) async {
    final record = await _pb.collection(AppConstants.colFinances).create(
      body: {
        'user': userId,
        'type': type,
        'category': category,
        'amount': amount,
        'note': note,
        'date': (date ?? DateTime.now()).toIso8601String(),
      },
      headers: PocketBaseService.instance.authHeaders(),
    );
    return FinanceModel.fromJson({...record.toJson(), ...record.data});
  }

  // Update finance record
  Future<FinanceModel> updateFinance({
    required String financeId,
    String? type,
    String? category,
    double? amount,
    String? note,
    DateTime? date,
  }) async {
    final body = <String, dynamic>{};
    if (type != null) body['type'] = type;
    if (category != null) body['category'] = category;
    if (amount != null) body['amount'] = amount;
    if (note != null) body['note'] = note;
    if (date != null) body['date'] = date.toIso8601String();

    final record = await _pb.collection(AppConstants.colFinances).update(
      financeId,
      body: body,
      headers: PocketBaseService.instance.authHeaders(),
    );

    return FinanceModel.fromJson({...record.toJson(), ...record.data});
  }

  // Delete finance record
  Future<void> deleteFinance(String financeId) async {
    await _pb.collection(AppConstants.colFinances).delete(
      financeId,
      headers: PocketBaseService.instance.authHeaders(),
    );
  }

  // Get monthly summary
  Future<Map<String, double>> getMonthlySummary({
    required String userId,
    required int month,
    required int year,
  }) async {
    final finances = await getFinances(
      userId: userId,
      month: month,
      year: year,
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

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  // Get total balance (all time)
  Future<double> getTotalBalance({required String userId}) async {
    final all = await getFinances(userId: userId);
    double balance = 0;
    for (final f in all) {
      if (f.isIncome) {
        balance += f.amount;
      } else {
        balance -= f.amount;
      }
    }
    return balance;
  }

  // Get expenses by category (for chart)
  Future<Map<String, double>> getExpenseByCategory({
    required String userId,
    int? month,
    int? year,
  }) async {
    final finances = await getFinances(
      userId: userId,
      type: 'expense',
      month: month,
      year: year,
    );

    final Map<String, double> result = {};
    for (final f in finances) {
      result[f.category] = (result[f.category] ?? 0) + f.amount;
    }
    return result;
  }

  // Get monthly trend (last 6 months)
  Future<List<Map<String, dynamic>>> getMonthlyTrend({
    required String userId,
  }) async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> trend = [];

    for (int i = 5; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;

      final summary = await getMonthlySummary(
        userId: userId,
        month: adjustedMonth,
        year: year,
      );

      trend.add({
        'month': adjustedMonth,
        'year': year,
        'income': summary['income'] ?? 0,
        'expense': summary['expense'] ?? 0,
        'balance': summary['balance'] ?? 0,
      });
    }

    return trend;
  }
}
