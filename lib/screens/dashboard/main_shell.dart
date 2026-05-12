import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/tasks')) return 1;
    if (location.startsWith('/finance')) return 2;
    if (location.startsWith('/ai')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/tasks'); break;
      case 2: context.go('/finance'); break;
      case 3: context.go('/ai'); break;
      case 4: context.go('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Beranda',
                  isActive: currentIndex == 0,
                  onTap: () => _onTap(context, 0),
                ),
                _NavItem(
                  icon: Icons.check_circle_outline,
                  activeIcon: Icons.check_circle_rounded,
                  label: 'Tugas',
                  isActive: currentIndex == 1,
                  onTap: () => _onTap(context, 1),
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'Keuangan',
                  isActive: currentIndex == 2,
                  onTap: () => _onTap(context, 2),
                ),
                _NavItem(
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome,
                  label: 'AI',
                  isActive: currentIndex == 3,
                  isAI: true,
                  onTap: () => _onTap(context, 3),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profil',
                  isActive: currentIndex == 4,
                  onTap: () => _onTap(context, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final bool isAI;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isAI = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isAI && isActive)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(activeIcon, color: Colors.white, size: 20),
              )
            else
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
