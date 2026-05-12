import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// STEP 18 — Notification Service
/// flutter_local_notifications v21 menggunakan named parameters untuk semua method
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'aura_task_reminders';
  static const _channelName = 'Task Reminders';
  static const _channelDesc = 'Notifikasi pengingat deadline tugas AURA';

  Future<void> init() async {
    // Init timezone
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    // Init plugin — v21 uses named parameter `settings:`
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Request permissions on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedule reminder 1 jam sebelum deadline
  Future<void> scheduleTaskReminder({
    required int notifId,
    required String taskTitle,
    required DateTime deadline,
  }) async {
    final reminderTime = deadline.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) {
      await showImmediateReminder(
        notifId: notifId,
        taskTitle: taskTitle,
        isOverdue: true,
      );
      return;
    }

    // v21 — semua named parameters
    await _plugin.zonedSchedule(
      id: notifId,
      title: '⏰ Pengingat Tugas — AURA',
      body: '$taskTitle jatuh tempo dalam 1 jam!',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Tampilkan notif segera
  Future<void> showImmediateReminder({
    required int notifId,
    required String taskTitle,
    bool isOverdue = false,
  }) async {
    // v21 — semua named parameters
    await _plugin.show(
      id: notifId,
      title: isOverdue
          ? '🚨 Tugas Overdue — AURA'
          : '⏰ Pengingat Tugas — AURA',
      body: isOverdue
          ? '$taskTitle sudah melewati deadline!'
          : '$taskTitle segera jatuh tempo!',
      notificationDetails: _buildDetails(),
    );
  }

  /// Cancel reminder spesifik
  Future<void> cancelReminder(int notifId) async {
    // v21 — named parameter
    await _plugin.cancel(id: notifId);
  }

  /// Cancel semua reminder
  Future<void> cancelAll() async => _plugin.cancelAll();

  NotificationDetails _buildDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF7C3AED),
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Generate unique notification ID dari task ID string
  static int taskNotifId(String taskId) =>
      taskId.hashCode.abs() % 2147483647;
}
