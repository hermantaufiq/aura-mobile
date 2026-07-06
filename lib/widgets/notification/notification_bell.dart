import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';

class NotificationBell extends ConsumerWidget {
  final bool showBadge;
  final double size;
  final Color? color;
  
  const NotificationBell({
    super.key,
    this.showBadge = true,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => context.push('/notifications'),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Icon(
              Icons.notifications_outlined,
              size: size,
              color: color ?? (isDark ? Colors.white70 : AppColors.textPrimary),
            ),
            
            // Badge for unread notifications
            if (showBadge && unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NotificationBellAnimated extends ConsumerStatefulWidget {
  final bool showBadge;
  final double size;
  final Color? color;
  
  const NotificationBellAnimated({
    super.key,
    this.showBadge = true,
    this.size = 24.0,
    this.color,
  });

  @override
  ConsumerState<NotificationBellAnimated> createState() => 
      _NotificationBellAnimatedState();
}

class _NotificationBellAnimatedState extends ConsumerState<NotificationBellAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  int _previousUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Trigger animation when unread count increases
    if (unreadCount > _previousUnreadCount && _previousUnreadCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerAnimation());
    }
    _previousUnreadCount = unreadCount;
    
    return GestureDetector(
      onTap: () => context.push('/notifications'),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final shakeValue = _shakeAnimation.value;
            return Transform.rotate(
              angle: shakeValue * 0.3 * (1 - shakeValue) * 6.28, // Shake effect
              child: Stack(
                children: [
                  Icon(
                    unreadCount > 0 
                        ? Icons.notifications_active
                        : Icons.notifications_outlined,
                    size: widget.size,
                    color: widget.color ?? 
                        (isDark ? Colors.white70 : AppColors.textPrimary),
                  ),
                  
                  // Animated badge
                  if (widget.showBadge && unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: AnimatedScale(
                        scale: shakeValue > 0 ? 1.0 + (shakeValue * 0.2) : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4, 
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}