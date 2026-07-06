import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import 'task_model.dart';

class AiUserContext {
  final List<TaskModel> pendingTasks;
  final List<TaskModel> inProgressTasks;
  final List<TaskModel> overdueTasks;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final Map<String, double> expenseByCategory;
  final int month;
  final int year;

  const AiUserContext({
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.overdueTasks,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.expenseByCategory,
    required this.month,
    required this.year,
  });

  String toPromptSection() {
    final monthName = DateFormat.MMMM('id_ID').format(DateTime(year, month));
    final buffer = StringBuffer();

    buffer.writeln('DATA PENGGUNA SAAT INI ($monthName $year):');
    buffer.writeln();

    buffer.writeln('📋 TUGAS:');
    buffer.writeln('- Pending: ${pendingTasks.length}');
    buffer.writeln('- Sedang dikerjakan: ${inProgressTasks.length}');
    buffer.writeln('- Terlambat: ${overdueTasks.length}');

    if (overdueTasks.isNotEmpty) {
      buffer.writeln('  Tugas terlambat:');
      for (final t in overdueTasks.take(5)) {
        buffer.writeln('  • ${t.title} (${_priorityLabel(t.priority)})');
      }
    }

    if (pendingTasks.isNotEmpty) {
      buffer.writeln('  Tugas pending:');
      for (final t in pendingTasks.take(5)) {
        final deadline = t.deadline != null
            ? DateFormat('d MMM', 'id_ID').format(t.deadline!)
            : 'tanpa deadline';
        buffer.writeln('  • ${t.title} — $deadline (${_priorityLabel(t.priority)})');
      }
    }

    buffer.writeln();
    buffer.writeln('💰 KEUANGAN BULAN INI:');
    buffer.writeln('- Pemasukan: ${_formatRp(totalIncome)}');
    buffer.writeln('- Pengeluaran: ${_formatRp(totalExpense)}');
    buffer.writeln('- Saldo: ${_formatRp(balance)}');

    if (expenseByCategory.isNotEmpty) {
      buffer.writeln('- Pengeluaran per kategori:');
      final sorted = expenseByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted.take(5)) {
        buffer.writeln('  • ${e.key}: ${_formatRp(e.value)}');
      }
    }

    buffer.writeln();
    buffer.writeln(
      'Gunakan data di atas untuk memberi jawaban yang personal dan relevan.',
    );

    return buffer.toString();
  }

  static String _formatRp(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);
  }

  static String _priorityLabel(String priority) {
    return switch (priority) {
      AppConstants.priorityHigh => 'tinggi',
      AppConstants.priorityLow => 'rendah',
      _ => 'sedang',
    };
  }
}
