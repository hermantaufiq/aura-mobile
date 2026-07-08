import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pocketbase_service.dart';
import '../models/user_model.dart';

// ─── Admin Stats Model ─────────────────────────────────────────────────────
class AdminStats {
  final int totalUsers;
  final int premiumUsers;
  final int totalTasks;
  final int totalFinance;
  final int todayAiRequests;
  final List<FlSpotData> revenueSpots;

  const AdminStats({
    required this.totalUsers,
    required this.premiumUsers,
    required this.totalTasks,
    required this.totalFinance,
    required this.todayAiRequests,
    required this.revenueSpots,
  });
}

class FlSpotData {
  final double x;
  final double y;
  const FlSpotData(this.x, this.y);
}

// ─── Admin Stats Provider ──────────────────────────────────────────────────
final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) async {
  final pb = PocketBaseService.instance.pb;

  // Fetch real data in parallel
  final results = await Future.wait([
    pb.collection('users').getList(perPage: 1),
    pb.collection('users').getList(perPage: 1, filter: 'is_premium = true'),
    pb.collection('tasks').getList(perPage: 1),
    pb.collection('finances').getList(perPage: 1),
  ]);

  final totalUsers = results[0].totalItems;
  final premiumUsers = results[1].totalItems;
  final totalTasks = results[2].totalItems;
  final totalFinance = results[3].totalItems;

  // Get AI daily count sum from all users today
  int todayAiRequests = 0;
  try {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final aiUsers = await pb.collection('users').getFullList(
      filter: 'ai_last_reset >= "$startOfDay"',
    );
    todayAiRequests = aiUsers.fold<int>(0, (sum, r) => sum + ((r.data['ai_daily_count'] as int?) ?? 0));
  } catch (_) {}

  // Build revenue spots from recent premium users (last 7 days)
  final revenueSpots = <FlSpotData>[];
  try {
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final startDay = DateTime(day.year, day.month, day.day).toIso8601String();
      final endDay = DateTime(day.year, day.month, day.day, 23, 59, 59).toIso8601String();
      final records = await pb.collection('users').getList(
        perPage: 1,
        filter: 'is_premium = true && premium_expired_at >= "$startDay" && premium_expired_at <= "$endDay"',
      );
      revenueSpots.add(FlSpotData((7 - i).toDouble(), records.totalItems.toDouble()));
    }
  } catch (_) {
    // Fallback to empty data if error
    for (int i = 1; i <= 7; i++) {
      revenueSpots.add(FlSpotData(i.toDouble(), 0));
    }
  }

  return AdminStats(
    totalUsers: totalUsers,
    premiumUsers: premiumUsers,
    totalTasks: totalTasks,
    totalFinance: totalFinance,
    todayAiRequests: todayAiRequests,
    revenueSpots: revenueSpots,
  );
});

// ─── Admin Users Provider ──────────────────────────────────────────────────
final adminUsersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final pb = PocketBaseService.instance.pb;
  final records = await pb.collection('users').getFullList(sort: '-created');
  return records.map((r) => UserModel.fromJson({...r.toJson(), ...r.data})).toList();
});

// ─── Search Query Provider ─────────────────────────────────────────────────
final adminUserSearchProvider = StateProvider.autoDispose<String>((ref) => '');

// ─── Admin Actions ─────────────────────────────────────────────────────────
final adminActionsProvider = Provider((ref) => AdminActions(ref));

class AdminActions {
  final Ref _ref;
  const AdminActions(this._ref);

  /// Give premium to a user for X days
  Future<void> giftPremium(String userId, int days) async {
    final pb = PocketBaseService.instance.pb;
    final record = await pb.collection('users').getOne(userId);
    
    final now = DateTime.now();
    DateTime newExpiry;
    
    // Extend from current expiry if still premium, otherwise from now
    final currentExpiry = record.data['premium_expired_at'] != null
        ? DateTime.tryParse(record.data['premium_expired_at'].toString())
        : null;
    
    if (currentExpiry != null && currentExpiry.isAfter(now)) {
      newExpiry = currentExpiry.add(Duration(days: days));
    } else {
      newExpiry = now.add(Duration(days: days));
    }
    
    await pb.collection('users').update(userId, body: {
      'is_premium': true,
      'premium_expired_at': newExpiry.toIso8601String(),
    });
    
    _ref.invalidate(adminUsersProvider);
    _ref.invalidate(adminStatsProvider);
  }

  /// Revoke premium from a user
  Future<void> revokePremium(String userId) async {
    final pb = PocketBaseService.instance.pb;
    await pb.collection('users').update(userId, body: {
      'is_premium': false,
      'premium_expired_at': null,
    });
    _ref.invalidate(adminUsersProvider);
    _ref.invalidate(adminStatsProvider);
  }

  /// Broadcast notification to all users
  Future<int> broadcastNotification(String title, String body) async {
    final pb = PocketBaseService.instance.pb;
    final users = await pb.collection('users').getFullList(
      filter: 'role = "user"',
    );
    
    int successCount = 0;
    for (final user in users) {
      try {
        await pb.collection('notifications').create(body: {
          'user': user.id,
          'title': title,
          'body': body,
          'type': 'announcement',
          'is_read': false,
        });
        successCount++;
      } catch (_) {}
    }
    return successCount;
  }
}
