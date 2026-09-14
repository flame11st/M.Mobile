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
    final horizontalMargin = Md3NavigationMetrics.horizontalMarginFor(context);

    return Padding(
      key: const ValueKey('root-navigation-safe-area'),
      padding: EdgeInsets.fromLTRB(
        horizontalMargin,
        0,
        horizontalMargin,
        bottomMargin,
      ),
      child: Md3LiquidGlass(
        borderRadius: BorderRadius.circular(Md3Radius.navigation),
        tint: Md3Colors.glassTint,
        borderColor: Md3Colors.navigationGlassBorder,
        shadows: Md3Shadows.navigation,
        child: SizedBox(
          key: const ValueKey('root-navigation-dock'),
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
    final selectionHorizontalPadding =
        MediaQuery.sizeOf(context).width >= 390 ? 12.0 : 6.0;

    return Expanded(
      flex: flex,
      child: Semantics(
        key: ValueKey('root-navigation-item-$index'),
        container: true,
        button: true,
        selected: selected,
        label: '$label tab, ${index + 1} of 5',
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Md3NavigationMetrics.itemHorizontalPadding,
            vertical: Md3NavigationMetrics.itemVerticalPadding,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(
                Md3Radius.navigationSelection,
              ),
              onTap: onTap,
              child: AnimatedContainer(
                key: ValueKey('root-navigation-selection-$index'),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : Md3Durations.standard,
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(
                  minHeight: Md3NavigationMetrics.itemMinimumHeight,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: selectionHorizontalPadding,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Md3Colors.primarySoft.withValues(alpha: 0.96)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    Md3Radius.navigationSelection,
                  ),
                  border: selected
                      ? Border.all(
                          color: Md3Colors.navigationSelectionBorder,
                        )
                      : null,
                  boxShadow: selected ? Md3Shadows.navigationSelection : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? selectedIcon ?? icon : icon,
                      size: Md3NavigationMetrics.iconSize,
                      color: foreground,
                    ),
                    const SizedBox(height: Md3NavigationMetrics.labelGap),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: MediaQuery.withClampedTextScaling(
                        minScaleFactor: 1,
                        maxScaleFactor: 1.3,
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: Md3Typography.navigationLabel.copyWith(
                            color: foreground,
                            fontSize: Md3NavigationMetrics.labelSize,
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
