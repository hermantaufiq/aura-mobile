import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/notification/notification_item.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NotificationType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    final notificationNotifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: AppTextStyles.of(context).headlineMedium,
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (notificationState.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () async {
                await notificationNotifier.markAllAsRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua notifikasi ditandai sebagai dibaca'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
          PopupMenuButton<NotificationType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (type) {
              setState(() => _selectedFilter = type);
              notificationNotifier.loadNotifications(type: type);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Semua')),
              ...NotificationType.values.map(
                (type) => PopupMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Text(type.icon),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Belum Dibaca (${notificationState.unreadCount})'),
            const Tab(text: 'Semua'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(
              context, notificationState, notificationState.unreadNotifications, true),
          _buildNotificationList(
              context, notificationState, notificationState.notifications, false),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    NotificationState notificationState,
    List<NotificationModel> notifications,
    bool isUnreadTab,
  ) {
    if (notificationState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnreadTab ? Icons.notifications_off : Icons.notifications_none,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              isUnreadTab ? 'Tidak ada notifikasi baru' : 'Belum ada notifikasi',
              style: AppTextStyles.of(context).bodyLarge.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            if (isUnreadTab) ...[
              const SizedBox(height: 8),
              Text(
                'Notifikasi baru akan muncul di sini',
                style: AppTextStyles.of(context)
                    .bodyMedium
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(notificationProvider.notifier)
            .loadNotifications(type: _selectedFilter);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationItem(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onDismiss: () => _handleNotificationDismiss(notification),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }
    if (!mounted) return;

    final data = notification.data;
    final action = data?['action'] as String?;

    switch (action) {
      case 'view_task':
        final taskId = data?['taskId'] as String?;
        context.push(taskId != null ? '/tasks/edit/$taskId' : '/tasks');
        break;
      case 'view_finance':
        context.push('/finance');
        break;
      case 'view_ai':
        context.push('/ai');
        break;
      case 'celebrate':
        _showCelebrationDialog();
        break;
      default:
        break;
    }
  }

  void _handleNotificationDismiss(NotificationModel notification) async {
    final success = await ref
        .read(notificationProvider.notifier)
        .deleteNotification(notification.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi dihapus'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showCelebrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Selamat!'),
        content: const Text('Tugas berhasil diselesaikan! Kerja bagus!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Terima kasih!'),
          ),
        ],
      ),
    );
  }
}
