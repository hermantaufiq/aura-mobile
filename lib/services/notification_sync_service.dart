import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../models/task_model.dart';
import 'notification_service.dart';
import 'task_service.dart';
import 'finance_service.dart';

/// Scans existing tasks & finances, then creates relevant notifications.
/// Safe to call on every login — uses dedup keys to avoid duplicates.
class NotificationSyncService {
  final NotificationService _notifService;
  final TaskService _taskService;
  final FinanceService _financeService;

  NotificationSyncService({
    required NotificationService notifService,
    required TaskService taskService,
    required FinanceService financeService,
  })  : _notifService = notifService,
        _taskService = taskService,
        _financeService = financeService;

  /// Entry point — call once after user is authenticated.
  Future<void> syncAll(String userId) async {
    if (userId.isEmpty) return;

    // Run both syncs concurrently
    await Future.wait([
      _syncTasks(userId),
      _syncFinances(userId),
    ]);
  }

  // ── Task sync ─────────────────────────────────────────────────────────────

  Future<void> _syncTasks(String userId) async {
    try {
      final tasks = await _taskService.getTasks(userId: userId);

      // Fetch existing notification titles to avoid exact duplicates
      final existing = await _notifService.getNotifications(
        userId: userId,
        limit: 200,
      );
      final existingTitlesMessages = existing
          .map((n) => '${n.title}|${n.message}')
          .toSet();

      final now = DateTime.now();

      for (final task in tasks) {
        if (task.status == 'done') continue; // skip completed tasks

        // ── Overdue tasks ────────────────────────────────────────────────
        if (task.isOverdue && task.deadline != null) {
          final daysOverdue = now.difference(task.deadline!).inDays;
          const title = 'Tugas Terlambat! ⚠️';
          final message =
              'Tugas "${task.title}" sudah terlambat $daysOverdue hari. Segera selesaikan!';

          if (!existingTitlesMessages.contains('$title|$message')) {
            await _safeCreate(
              userId: userId,
              title: title,
              message: message,
              type: NotificationType.taskOverdue,
              priority: NotificationPriority.urgent,
              data: {'action': 'view_task', 'taskId': task.id},
            );
          }
          continue;
        }

        // ── Upcoming deadlines ───────────────────────────────────────────
        if (task.deadline != null) {
          final daysLeft = task.deadline!.difference(now).inDays;
          _buildDeadlineNotif(
            task: task,
            daysLeft: daysLeft,
            existingKeys: existingTitlesMessages,
            onCreate: (title, message, priority) => _safeCreate(
              userId: userId,
              title: title,
              message: message,
              type: NotificationType.taskDeadline,
              priority: priority,
              data: {'action': 'view_task', 'taskId': task.id},
            ),
          );
        }
      }

      // ── High-priority pending tasks (no deadline) ────────────────────────
      final highPending = tasks
          .where((t) =>
              t.priority == 'high' &&
              t.status == 'pending' &&
              t.deadline == null)
          .toList();

      if (highPending.isNotEmpty) {
        final names = highPending.take(3).map((t) => '"${t.title}"').join(', ');
        const title = 'Tugas Prioritas Tinggi 🔴';
        final message =
            'Kamu punya ${highPending.length} tugas prioritas tinggi yang belum dimulai: $names';

        if (!existingTitlesMessages.any((k) => k.startsWith(title))) {
          await _safeCreate(
            userId: userId,
            title: title,
            message: message,
            type: NotificationType.taskOverdue,
            priority: NotificationPriority.high,
            data: {'action': 'view_task'},
          );
        }
      }
    } catch (_) {
      // Silent — don't crash the app if sync fails
    }
  }

  void _buildDeadlineNotif({
    required TaskModel task,
    required int daysLeft,
    required Set<String> existingKeys,
    required Future<void> Function(
            String title, String message, NotificationPriority priority)
        onCreate,
  }) {
    String title;
    String message;
    NotificationPriority priority;

    if (daysLeft == 0) {
      title = 'Deadline Hari Ini! 🚨';
      message = 'Tugas "${task.title}" harus diselesaikan hari ini!';
      priority = NotificationPriority.urgent;
    } else if (daysLeft == 1) {
      title = 'Deadline Besok! ⏰';
      message = 'Tugas "${task.title}" akan berakhir besok. Segera selesaikan!';
      priority = NotificationPriority.urgent;
    } else if (daysLeft <= 3) {
      title = 'Deadline $daysLeft Hari Lagi ⏰';
      message = 'Tugas "${task.title}" akan berakhir dalam $daysLeft hari.';
      priority = NotificationPriority.high;
    } else if (daysLeft <= 7) {
      title = 'Deadline Minggu Ini 📅';
      message =
          'Tugas "${task.title}" akan berakhir dalam $daysLeft hari (${_fmtDate(task.deadline!)}).';
      priority = NotificationPriority.medium;
    } else {
      return; // nothing to notify for far deadlines
    }

    if (!existingKeys.any((k) => k.startsWith(title))) {
      onCreate(title, message, priority);
    }
  }

  // ── Finance sync ──────────────────────────────────────────────────────────

  Future<void> _syncFinances(String userId) async {
    try {
      final now = DateTime.now();
      final finances = await _financeService.getFinances(
        userId: userId,
        month: now.month,
        year: now.year,
      );

      if (finances.isEmpty) return;

      final existing = await _notifService.getNotifications(
        userId: userId,
        limit: 200,
      );
      final existingKeys = existing.map((n) => '${n.title}|${n.message}').toSet();

      // Calculate totals
      double totalIncome = 0;
      double totalExpense = 0;
      final Map<String, double> expenseByCategory = {};

      for (final f in finances) {
        if (f.isIncome) {
          totalIncome += f.amount;
        } else {
          totalExpense += f.amount;
          expenseByCategory[f.category] =
              (expenseByCategory[f.category] ?? 0) + f.amount;
        }
      }

      final fmt = NumberFormat.currency(
          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

      // ── Negative balance warning ─────────────────────────────────────────
      final balance = totalIncome - totalExpense;
      if (balance < 0) {
        const title = 'Saldo Negatif! 🔴';
        final message =
            'Pengeluaran bulan ini melebihi pemasukan sebesar ${fmt.format(balance.abs())}. Perhatikan keuanganmu!';
        if (!existingKeys.any((k) => k.startsWith(title))) {
          await _safeCreate(
            userId: userId,
            title: title,
            message: message,
            type: NotificationType.budgetAlert,
            priority: NotificationPriority.urgent,
            data: {'action': 'view_finance'},
          );
        }
      }

      // ── High expense category warning (>40% of income or >2 jt) ─────────
      if (totalIncome > 0) {
        for (final entry in expenseByCategory.entries) {
          final pct = (entry.value / totalIncome * 100).round();
          if (pct >= 40 || entry.value >= 2000000) {
            final title = 'Pengeluaran ${_capitalize(entry.key)} Tinggi 💸';
            final message =
                'Pengeluaran ${entry.key} bulan ini ${fmt.format(entry.value)} ($pct% dari pemasukan).';
            if (!existingKeys.any((k) => k.startsWith(title))) {
              await _safeCreate(
                userId: userId,
                title: title,
                message: message,
                type: NotificationType.budgetAlert,
                priority: pct >= 60
                    ? NotificationPriority.high
                    : NotificationPriority.medium,
                data: {'action': 'view_finance', 'category': entry.key},
              );
            }
          }
        }
      }

      // ── Monthly summary (show at end of month or if past 20th) ───────────
      if (now.day >= 20) {
        final completedTasks = await _taskService
            .getTasks(userId: userId)
            .then((t) => t.where((x) => x.status == 'done').length);

        final balanceText = balance >= 0 ? 'surplus' : 'defisit';
        const title = 'Ringkasan Bulan Ini 📊';
        final message =
            '$completedTasks tugas selesai • $balanceText ${fmt.format(balance.abs())}';

        if (!existingKeys.any((k) => k.startsWith(title))) {
          await _safeCreate(
            userId: userId,
            title: title,
            message: message,
            type: NotificationType.monthlySummary,
            priority: NotificationPriority.low,
            data: {
              'action': 'view_summary',
              'completedTasks': completedTasks,
              'totalIncome': totalIncome,
              'totalExpense': totalExpense,
              'balance': balance,
            },
          );
        }
      }

      // ── No income this month ─────────────────────────────────────────────
      if (totalIncome == 0 && totalExpense > 0) {
        const title = 'Belum Ada Pemasukan 💰';
        final message =
            'Kamu sudah mengeluarkan ${fmt.format(totalExpense)} bulan ini tapi belum mencatat pemasukan.';
        if (!existingKeys.any((k) => k.startsWith(title))) {
          await _safeCreate(
            userId: userId,
            title: title,
            message: message,
            type: NotificationType.expenseReminder,
            priority: NotificationPriority.medium,
            data: {'action': 'view_finance'},
          );
        }
      }
    } catch (_) {
      // Silent
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _safeCreate({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    required NotificationPriority priority,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _notifService.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        priority: priority,
        data: data,
      );
    } catch (_) {
      // Ignore individual failures
    }
  }

  String _fmtDate(DateTime dt) =>
      DateFormat('dd MMM yyyy', 'id_ID').format(dt);

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
