import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/app_theme.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(
      label: 'Trang chủ',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: 'Loại',
      icon: Icons.category_outlined,
      activeIcon: Icons.category_rounded,
    ),
    _NavItem(
      label: 'Yêu thích',
      icon: Icons.favorite_outline_rounded,
      activeIcon: Icons.favorite_rounded,
    ),
    _NavItem(
      label: 'Lịch sử',
      icon: Icons.history_rounded,
      activeIcon: Icons.history_rounded,
    ),
  ];

  // Using IndexedStack to keep each tab's state alive while switching
  static const List<Widget> _screens = [
    HomeScreen(),
    CategoriesScreen(),
    FavoritesScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.background.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: context.colors.divider.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / _navItems.length;
                  return Stack(
                    children: [
                      Row(
                        children: List.generate(_navItems.length, (index) {
                          return Expanded(
                            child: _buildNavItem(context, index),
                          );
                        }),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        top: 0,
                        left: _currentIndex * itemWidth,
                        child: SizedBox(
                          width: itemWidth,
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              width: 52,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _navItems[_currentIndex].label == 'Yêu thích'
                                    ? Colors.red
                                    : context.colors.primary,
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index) {
    final item = _navItems[index];
    final isActive = _currentIndex == index;
    final activeColor = item.label == 'Yêu thích'
        ? Colors.red
        : context.colors.primary;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              size: 24,
              color: isActive ? activeColor : context.colors.textHint,
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: context.textTheme.labelSmall!.copyWith(
                color: isActive ? activeColor : context.colors.textHint,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11.5,
              ),
              child: Text(item.label),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
