import '../core/constants/app_constants.dart';
import '../models/ai_user_context.dart';
import 'finance_service.dart';
import 'task_service.dart';

class AiContextBuilder {
  final TaskService _taskService;
  final FinanceService _financeService;

  AiContextBuilder(this._taskService, this._financeService);

  Future<AiUserContext> build(String userId) async {
    final now = DateTime.now();
    final month = now.month;
    final year = now.year;

    final tasks = await _taskService.getTasks(userId: userId);
    final pending =
        tasks.where((t) => t.status == AppConstants.statusPending).toList();
    final inProgress =
        tasks.where((t) => t.status == AppConstants.statusInProgress).toList();
    final overdue = tasks.where((t) => t.isOverdue).toList();

    final summary = await _financeService.getMonthlySummary(
      userId: userId,
      month: month,
      year: year,
    );
    final expenseByCategory = await _financeService.getExpenseByCategory(
      userId: userId,
      month: month,
      year: year,
    );

    return AiUserContext(
      pendingTasks: pending,
      inProgressTasks: inProgress,
      overdueTasks: overdue,
      totalIncome: summary['income'] ?? 0,
      totalExpense: summary['expense'] ?? 0,
      balance: summary['balance'] ?? 0,
      expenseByCategory: expenseByCategory,
      month: month,
      year: year,
    );
  }
}
