import 'package:flutter/material.dart';
import 'Shared/md3_ui.dart';

class MoviesBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const MoviesBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomMargin = Md3NavigationMetrics.bottomMargin(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomMargin),
      child: Md3LiquidGlass(
        borderRadius: BorderRadius.circular(28),
        tint: Colors.white.withValues(alpha: 0.78),
        borderColor: Colors.white.withValues(alpha: 0.72),
        shadows: [
          BoxShadow(
            color: const Color(0xff102a43).withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
        child: SizedBox(
          height: Md3NavigationMetrics.dockHeight,
          child: Row(
            children: [
              _NavItem(
                index: 0,
                flex: 64,
                label: 'Discover',
                icon: Icons.auto_awesome_outlined,
                selectedIcon: Icons.auto_awesome_rounded,
                selected: selectedIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _NavItem(
                index: 1,
                flex: 50,
                label: 'Search',
                icon: Icons.search_rounded,
                selected: selectedIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              _NavItem(
                index: 2,
                flex: 75,
                label: 'My Movies',
                icon: Icons.video_library_outlined,
                selectedIcon: Icons.video_library_rounded,
                selected: selectedIndex == 2,
                onTap: () => onTabSelected(2),
              ),
              _NavItem(
                index: 3,
                flex: 49,
                label: 'Lists',
                icon: Icons.list_alt_rounded,
                selectedIcon: Icons.list_alt_rounded,
                selected: selectedIndex == 3,
                onTap: () => onTabSelected(3),
              ),
              _NavItem(
                index: 4,
                flex: 58,
                label: 'Settings',
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings_rounded,
                selected: selectedIndex == 4,
                onTap: () => onTabSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int flex;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.flex,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Md3Colors.primary : Md3Colors.muted;

    return Expanded(
      flex: flex,
      child: Semantics(
        key: ValueKey('root-navigation-item-$index'),
        container: true,
        button: true,
        selected: selected,
        label: '$label tab, ${index + 1} of 5',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(
                  color: selected
                      ? Md3Colors.primarySoft.withValues(alpha: 0.96)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  border: selected
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.82),
                        )
                      : null,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Md3Colors.primary.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? selectedIcon ?? icon : icon,
                      size: 22,
                      color: foreground,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: MediaQuery.withClampedTextScaling(
                        minScaleFactor: 1,
                        maxScaleFactor: 1.3,
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
