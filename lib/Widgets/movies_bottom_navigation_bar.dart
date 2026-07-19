import 'package:flutter/material.dart';
import 'package:mmobile/Widgets/movies_lists_page.dart';
import 'movies_filter.dart';
import 'Providers/movies_state.dart';
import 'search_delegate.dart';
import 'settings.dart';
import 'Shared/md3_ui.dart';
import 'package:mmobile/Helpers/route_helper.dart';
import 'package:provider/provider.dart';

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
    final moviesState = Provider.of<MoviesState>(context);
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
                label: 'Discover',
                icon: Icons.auto_awesome_outlined,
                selectedIcon: Icons.auto_awesome_rounded,
                selected: selectedIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _NavItem(
                label: 'Search',
                icon: Icons.search_rounded,
                onTap: () => showSearch(
                  context: context,
                  delegate: MSearchDelegate(),
                ),
              ),
              _NavItem(
                label: 'My Movies',
                icon: moviesState.isAnyFilterSelected()
                    ? Icons.filter_alt_rounded
                    : Icons.movie_filter_outlined,
                selectedIcon: Icons.movie_filter_rounded,
                selected: selectedIndex == 2,
                showDot: moviesState.isAnyFilterSelected(),
                onTap: () {
                  if (selectedIndex == 2) {
                    showModalBottomSheet<void>(
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) => MoviesFilter(),
                    );
                    return;
                  }
                  onTabSelected(2);
                },
              ),
              _NavItem(
                label: 'Lists',
                icon: Icons.list_alt_rounded,
                onTap: () => Navigator.of(context).push(
                  RouteHelper.createRoute(
                    () => const MoviesListsPage(initialPageIndex: 0),
                  ),
                ),
              ),
              _NavItem(
                label: 'Settings',
                icon: Icons.settings_outlined,
                onTap: () => Navigator.of(context).push(
                  RouteHelper.createRoute(() => Settings()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.selected = false,
    this.showDot = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Md3Colors.primary : Md3Colors.muted;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
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
                      ? Border.all(color: Colors.white.withValues(alpha: 0.82))
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
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          selected ? selectedIcon ?? icon : icon,
                          size: 22,
                          color: foreground,
                        ),
                        if (showDot)
                          Positioned(
                            right: -4,
                            top: -2,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Md3Colors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w700,
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
