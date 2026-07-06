import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:aura_mobile/utils/utils.dart';
import 'package:aura_mobile/models/user_model.dart';
import 'package:aura_mobile/models/task_model.dart';
import 'package:aura_mobile/models/finance_model.dart';

// ─── STEP 19: Final Testing ────────────────────────────────────────────────

void main() {
  // Init intl locale once before all tests
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  // ══════════════════════════════════════════════════════════════════════════
  // UNIT TESTS — Utils
  // ══════════════════════════════════════════════════════════════════════════

  group('[Utils] CurrencyFormatter', () {
    test('format: returns Rp format for 1 juta', () {
      final result = CurrencyFormatter.format(1000000);
      expect(result, contains('1.000.000'));
      expect(result, contains('Rp'));
    });

    test('format: handles zero correctly', () {
      final result = CurrencyFormatter.format(0);
      expect(result, contains('0'));
    });

    test('signed: adds + prefix for income', () {
      final result = CurrencyFormatter.signed(500000, isIncome: true);
      expect(result, startsWith('+'));
    });

    test('signed: adds - prefix for expense', () {
      final result = CurrencyFormatter.signed(500000);
      expect(result, startsWith('-'));
    });

    test('parse: extracts number from formatted string', () {
      final result = CurrencyFormatter.parse('Rp 1.000.000');
      expect(result, equals(1000000));
    });

    test('parse: returns 0 for empty string', () {
      final result = CurrencyFormatter.parse('');
      expect(result, equals(0));
    });
  });

  group('[Utils] DateFormatter', () {
    test('relative: today returns Hari ini', () {
      expect(DateFormatter.relative(DateTime.now()), equals('Hari ini'));
    });

    test('relative: tomorrow returns Besok', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(DateFormatter.relative(tomorrow), equals('Besok'));
    });

    test('relative: yesterday returns Kemarin', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateFormatter.relative(yesterday), equals('Kemarin'));
    });

    test('relative: 3 days from now', () {
      final future = DateTime.now().add(const Duration(days: 3));
      expect(DateFormatter.relative(future), contains('3 hari lagi'));
    });

    test('deadlineStatus: null returns Tanpa deadline', () {
      expect(DateFormatter.deadlineStatus(null), equals('Tanpa deadline'));
    });

    test('deadlineStatus: past date returns Overdue', () {
      final past = DateTime(2020, 1, 1);
      expect(DateFormatter.deadlineStatus(past), equals('Overdue'));
    });

    test('short: contains year and day', () {
      final date = DateTime(2025, 1, 25);
      final result = DateFormatter.short(date);
      expect(result, contains('25'));
      expect(result, contains('2025'));
    });
  });

  group('[Utils] AppValidator - email', () {
    test('valid email returns null (no error)', () {
      expect(AppValidator.email('user@example.com'), isNull);
    });

    test('empty email returns error', () {
      expect(AppValidator.email(''), isNotNull);
    });

    test('email without domain returns error', () {
      expect(AppValidator.email('useronly'), isNotNull);
    });

    test('email missing @ returns error', () {
      expect(AppValidator.email('useremail.com'), isNotNull);
    });
  });

  group('[Utils] AppValidator - password', () {
    test('8+ char password returns null', () {
      expect(AppValidator.password('securepass'), isNull);
    });

    test('short password (< 8) returns error', () {
      expect(AppValidator.password('abc'), isNotNull);
    });

    test('empty password returns error', () {
      expect(AppValidator.password(''), isNotNull);
    });
  });

  group('[Utils] AppValidator - amount', () {
    test('positive amount returns null', () {
      expect(AppValidator.amount('100000'), isNull);
    });

    test('zero amount returns error', () {
      expect(AppValidator.amount('0'), isNotNull);
    });

    test('empty amount returns error', () {
      expect(AppValidator.amount(''), isNotNull);
    });
  });

  group('[Utils] AppValidator - OTP', () {
    test('6 digit numeric OTP returns null', () {
      expect(AppValidator.otp('123456'), isNull);
    });

    test('5 digit OTP returns error', () {
      expect(AppValidator.otp('12345'), isNotNull);
    });

    test('alphanumeric OTP returns error', () {
      expect(AppValidator.otp('abc123'), isNotNull);
    });

    test('7 digit OTP returns error', () {
      expect(AppValidator.otp('1234567'), isNotNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // UNIT TESTS — Models
  // ══════════════════════════════════════════════════════════════════════════

  group('[Model] UserModel', () {
    final now = DateTime.now();

    const user = UserModel(
      id: 'u1',
      name: 'Ahmad Skripsi',
      email: 'ahmad@test.com',
      role: 'user',
      isVerified: true,
      isPremium: false,
      aiDailyCount: 3,
    );

    test('isPremiumActive: false when isPremium = false', () {
      expect(user.isPremiumActive, isFalse);
    });

    test('isPremiumActive: true when premium not expired', () {
      final premiumUser = user.copyWith(
        isPremium: true,
        premiumExpiredAt: now.add(const Duration(days: 30)),
      );
      expect(premiumUser.isPremiumActive, isTrue);
    });

    test('isPremiumActive: false when premium expired', () {
      final expiredUser = user.copyWith(
        isPremium: true,
        premiumExpiredAt: now.subtract(const Duration(days: 1)),
      );
      expect(expiredUser.isPremiumActive, isFalse);
    });

    test('copyWith: updates name while keeping other fields', () {
      final updated = user.copyWith(name: 'Nama Baru');
      expect(updated.name, equals('Nama Baru'));
      expect(updated.id, equals(user.id));
      expect(updated.email, equals(user.email));
    });

    test('fromJson: parses all fields correctly', () {
      final json = {
        'id': 'u2',
        'name': 'Test User',
        'email': 'test@test.com',
        'role': 'user',
        'is_verified': true,
        'is_premium': false,
        'ai_daily_count': 2,
      };
      final parsed = UserModel.fromJson(json);
      expect(parsed.id, equals('u2'));
      expect(parsed.name, equals('Test User'));
      expect(parsed.role, equals('user'));
      expect(parsed.aiDailyCount, equals(2));
    });

    test('role: admin user has admin role', () {
      final admin = user.copyWith(role: 'admin');
      expect(admin.role, equals('admin'));
    });
  });

  group('[Model] TaskModel', () {
    final now = DateTime.now();

    final overdueTask = TaskModel(
      id: 't1',
      userId: 'u1',
      title: 'Overdue Task',
      description: 'This is overdue',
      priority: 'high',
      status: 'pending',
      deadline: now.subtract(const Duration(hours: 2)),
      created: now,
      updated: now,
    );

    final futureTask = TaskModel(
      id: 't2',
      userId: 'u1',
      title: 'Future Task',
      description: '',
      priority: 'medium',
      status: 'pending',
      deadline: now.add(const Duration(days: 5)),
      created: now,
      updated: now,
    );

    final doneTask = TaskModel(
      id: 't3',
      userId: 'u1',
      title: 'Done Task',
      description: '',
      priority: 'low',
      status: 'done',
      deadline: now.subtract(const Duration(hours: 1)),
      created: now,
      updated: now,
    );

    test('isOverdue: true for past deadline with pending status', () {
      expect(overdueTask.isOverdue, isTrue);
    });

    test('isOverdue: false for done task even with past deadline', () {
      expect(doneTask.isOverdue, isFalse);
    });

    test('isOverdue: false for future deadline', () {
      expect(futureTask.isOverdue, isFalse);
    });

    test('isDueToday: true for today deadline', () {
      final todayTask = TaskModel(
        id: 't4', userId: 'u1', title: 'Today',
        description: '', priority: 'high', status: 'pending',
        deadline: DateTime(now.year, now.month, now.day, 23, 59),
        created: now, updated: now,
      );
      expect(todayTask.isDueToday, isTrue);
    });

    test('isDueToday: false for no deadline', () {
      final noDeadline = TaskModel(
        id: 't5', userId: 'u1', title: 'No Deadline',
        description: '', priority: 'low', status: 'pending',
        created: now, updated: now,
      );
      expect(noDeadline.isDueToday, isFalse);
    });

    test('fromJson: parses all required fields', () {
      final json = {
        'id': 't10',
        'user': 'u1',
        'title': 'Parsed Task',
        'description': 'Desc',
        'priority': 'high',
        'status': 'in_progress',
        'deadline': null,
        'created': now.toIso8601String(),
        'updated': now.toIso8601String(),
      };
      final parsed = TaskModel.fromJson(json);
      expect(parsed.title, equals('Parsed Task'));
      expect(parsed.priority, equals('high'));
      expect(parsed.status, equals('in_progress'));
    });

    test('copyWith: updates status while keeping title', () {
      final updated = overdueTask.copyWith(status: 'done');
      expect(updated.status, equals('done'));
      expect(updated.title, equals(overdueTask.title));
    });
  });

  group('[Model] FinanceModel', () {
    final now = DateTime.now();

    final income = FinanceModel(
      id: 'f1', userId: 'u1',
      type: 'income', category: 'Gaji',
      amount: 5000000.0, note: 'Gaji bulan ini',
      date: now, created: now, updated: now,
    );

    final expense = FinanceModel(
      id: 'f2', userId: 'u1',
      type: 'expense', category: 'Makanan & Minuman',
      amount: 150000.0, note: 'Makan siang',
      date: now, created: now, updated: now,
    );

    test('isIncome: true for income type', () {
      expect(income.isIncome, isTrue);
      expect(income.isExpense, isFalse);
    });

    test('isExpense: true for expense type', () {
      expect(expense.isExpense, isTrue);
      expect(expense.isIncome, isFalse);
    });

    test('amount: 5 juta stored correctly', () {
      expect(income.amount, equals(5000000.0));
    });

    test('fromJson: parses type and amount correctly', () {
      final json = {
        'id': 'f10',
        'user': 'u1',
        'type': 'expense',
        'category': 'Transportasi',
        'amount': 50000,
        'note': 'Bensin',
        'date': now.toIso8601String(),
        'created': now.toIso8601String(),
        'updated': now.toIso8601String(),
      };
      final parsed = FinanceModel.fromJson(json);
      expect(parsed.isExpense, isTrue);
      expect(parsed.amount, equals(50000.0));
      expect(parsed.category, equals('Transportasi'));
    });

    test('copyWith: updates amount while keeping type', () {
      final updated = income.copyWith(amount: 6000000);
      expect(updated.amount, equals(6000000));
      expect(updated.type, equals('income'));
    });
  });
}
