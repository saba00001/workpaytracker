import 'dart:ui';

import '../core/app_export.dart';

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  static const List<_TabSpec> _tabs = [
    _TabSpec(
      label: 'მთავარი',
      iconActive: Icons.home_rounded,
      iconInactive: Icons.home_outlined,
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'კალენდარი',
      iconActive: Icons.calendar_month_rounded,
      iconInactive: Icons.calendar_month_outlined,
      branchIndex: 1,
    ),
    _TabSpec(
      label: 'ისტორია',
      iconActive: Icons.receipt_long_rounded,
      iconInactive: Icons.receipt_long_outlined,
      branchIndex: 2,
    ),
    _TabSpec(
      label: 'პარამეტრები',
      iconActive: Icons.tune_rounded,
      iconInactive: Icons.tune_rounded,
      branchIndex: 3,
    ),
  ];

  int get _selectedIndex => widget.navigationShell.currentIndex;

  void _onTabTap(int visualIndex) {
    if (visualIndex == _selectedIndex) return;
    widget.navigationShell.goBranch(
      visualIndex,
      initialLocation: visualIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, (bottom > 0 ? bottom + 8 : 16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF111214).withAlpha(240),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withAlpha(18), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: const Color(0xFF10B981).withAlpha(8),
                  blurRadius: 40,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = i == _selectedIndex;

                return GestureDetector(
                  onTap: () => _onTabTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 72,
                    height: 64,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF10B981).withAlpha(22)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(
                                    scale: anim,
                                    child: FadeTransition(
                                      opacity: anim,
                                      child: child,
                                    ),
                                  ),
                              child: Icon(
                                isActive ? tab.iconActive : tab.iconInactive,
                                key: ValueKey('$i-$isActive'),
                                color: isActive
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF4B5563),
                                size: 21,
                              ),
                            ),
                            const SizedBox(height: 3),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isActive
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF4B5563),
                                letterSpacing: 0.1,
                              ),
                              child: Text(tab.label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  final String label;
  final IconData iconActive;
  final IconData iconInactive;
  final int branchIndex;

  const _TabSpec({
    required this.label,
    required this.iconActive,
    required this.iconInactive,
    required this.branchIndex,
  });
}
