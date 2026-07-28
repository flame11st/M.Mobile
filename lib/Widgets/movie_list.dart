import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Variables/variables.dart';
import 'package:mmobile/Widgets/empty_movies_card.dart';
import 'package:provider/provider.dart';

import 'Providers/movies_state.dart';
import 'Providers/user_state.dart';
import 'Shared/m_movies_animated_list.dart';
import 'Shared/md3_ui.dart';

class MovieList extends StatefulWidget {
  final VoidCallback onOpenDiscover;
  final VoidCallback onStartRating;
  final bool isRefreshing;
  final String? refreshError;
  final Future<void> Function()? onRetry;

  const MovieList({
    super.key,
    required this.onOpenDiscover,
    required this.onStartRating,
    this.isRefreshing = false,
    this.refreshError,
    this.onRetry,
  });

  @override
  State<StatefulWidget> createState() => MovieListState();
}

class MovieListState extends State<MovieList>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;
  final _watchlistScrollController = ScrollController();
  final _viewedScrollController = ScrollController();
  final _filterScrollController = ScrollController();
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(vsync: this, length: 2)
      ..addListener(_syncActiveTab);
  }

  @override
  void dispose() {
    AdManager.hideBanner();
    tabController
      ..removeListener(_syncActiveTab)
      ..dispose();
    _watchlistScrollController.dispose();
    _viewedScrollController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  void _syncActiveTab() {
    final nextIndex = tabController.index;
    if (nextIndex == _activeTabIndex || !mounted) {
      return;
    }

    setState(() => _activeTabIndex = nextIndex);
    Provider.of<MoviesState>(context, listen: false)
        .setCurrentTabIndex(nextIndex);
  }

  void _selectTab(int index) {
    if (index == _activeTabIndex) {
      unawaited(handleActiveTabTap());
      return;
    }

    setState(() => _activeTabIndex = index);
    Provider.of<MoviesState>(context, listen: false).setCurrentTabIndex(index);
    tabController.animateTo(
      index,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> handleActiveTabTap() async {
    final controller = _activeTabIndex == 1
        ? _viewedScrollController
        : _watchlistScrollController;
    if (!controller.hasClients) {
      return;
    }

    await controller.animateTo(
      0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalKey = GlobalKey();
    if (ModalRoute.of(context)?.isCurrent ?? true) {
      MyGlobals.activeKey = globalKey;
    }

    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    if (!userState.isIncognitoMode &&
        !userState.premiumPurchasedIncognito &&
        (userState.user == null || !userState.user!.premiumPurchased)) {
      if (ModalRoute.of(context)?.isCurrent ?? true) {
        AdManager.showBanner();
      }
    } else if (AdManager.bannerVisible) {
      AdManager.bannerVisible = false;
      AdManager.hideBanner();
    }

    final allViewedMovies = moviesState.userMovies
        .where((movie) => MovieRate.isViewed(movie.movieRate))
        .toList(growable: false);
    final hasCachedLibrary = moviesState.userMovies.isNotEmpty;
    final showRefreshBanner = widget.refreshError != null && hasCachedLibrary;

    return Scaffold(
      key: globalKey,
      resizeToAvoidBottomInset: false,
      backgroundColor: Md3Colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Semantics(
                header: true,
                child: const Text(
                  'My Movies',
                  key: Key('my-movies-page-title'),
                  style: TextStyle(
                    color: Md3Colors.text,
                    fontSize: 32,
                    height: 1.19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSegmentedBar(
              watchlistCount: moviesState.watchlistMovies.length,
              viewedCount: allViewedMovies.length,
            ),
            if (_activeTabIndex == 1) ...[
              const SizedBox(height: 12),
              _buildViewedFilters(moviesState, allViewedMovies),
            ],
            if (showRefreshBanner) ...[
              const SizedBox(height: 12),
              _buildRefreshBanner(),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  _buildWatchlistContent(moviesState, userState),
                  _buildViewedContent(
                    moviesState,
                    userState,
                    allViewedMovies,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedBar({
    required int watchlistCount,
    required int viewedCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Md3LiquidGlass(
        key: const Key('my-movies-segmented-bar'),
        blur: 20,
        padding: const EdgeInsets.all(4),
        borderRadius: BorderRadius.circular(24),
        tint: Colors.white.withValues(alpha: 0.8),
        borderColor: Colors.white.withValues(alpha: 0.88),
        shadows: const [
          BoxShadow(
            color: Color(0x120f253d),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              _LibrarySegment(
                key: const Key('my-movies-tab-watchlist'),
                label: 'Watchlist',
                semanticsLabel: 'Watchlist, $watchlistCount saved',
                icon: Icons.bookmark_outline_rounded,
                selectedIcon: Icons.bookmark_rounded,
                selected: _activeTabIndex == 0,
                onTap: () => _selectTab(0),
              ),
              _LibrarySegment(
                key: const Key('my-movies-tab-viewed'),
                label: 'Viewed',
                semanticsLabel: 'Viewed, $viewedCount rated',
                icon: Icons.check_circle_outline_rounded,
                selectedIcon: Icons.check_circle_rounded,
                selected: _activeTabIndex == 1,
                onTap: () => _selectTab(1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewedFilters(
    MoviesState moviesState,
    List<Movie> allViewedMovies,
  ) {
    final counts = <int, int>{
      MovieRate.liked: 0,
      MovieRate.okay: 0,
      MovieRate.notLiked: 0,
    };
    for (final movie in allViewedMovies) {
      if (counts.containsKey(movie.movieRate)) {
        counts[movie.movieRate] = counts[movie.movieRate]! + 1;
      }
    }

    final selectedRates = moviesState.selectedRates;
    final allSelected = selectedRates.length == 3;

    return Semantics(
      container: true,
      label: 'Viewed opinion filters',
      child: SingleChildScrollView(
        key: const Key('viewed-filter-scroll'),
        controller: _filterScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _ViewedFilterChip(
              key: const Key('viewed-filter-all'),
              label: 'All',
              count: allViewedMovies.length,
              selected: allSelected,
              selectedBackground: Md3Colors.primary,
              selectedForeground: Colors.white,
              onTap: moviesState.selectAllViewedRates,
            ),
            const SizedBox(width: 8),
            _ViewedFilterChip(
              key: const Key('viewed-filter-liked'),
              label: 'Liked',
              count: counts[MovieRate.liked]!,
              selected: !allSelected && selectedRates.contains(MovieRate.liked),
              selectedBackground: const Color(0xffe8f4ed),
              selectedForeground: Md3Colors.success,
              onTap: moviesState.changeLikedOnlyFilter,
            ),
            const SizedBox(width: 8),
            _ViewedFilterChip(
              key: const Key('viewed-filter-okay'),
              label: 'Okay',
              count: counts[MovieRate.okay]!,
              selected: !allSelected && selectedRates.contains(MovieRate.okay),
              selectedBackground: const Color(0xfffff4e4),
              selectedForeground: Md3Colors.warning,
              onTap: moviesState.changeOkayOnlyFilter,
            ),
            const SizedBox(width: 8),
            _ViewedFilterChip(
              key: const Key('viewed-filter-disliked'),
              label: 'Disliked',
              count: counts[MovieRate.notLiked]!,
              selected:
                  !allSelected && selectedRates.contains(MovieRate.notLiked),
              selectedBackground: const Color(0xfffceaec),
              selectedForeground: Md3Colors.danger,
              onTap: moviesState.changeNotLikedOnlyFilter,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshBanner() {
    final useCompactLayout = MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    final retry = widget.onRetry == null
        ? null
        : widget.isRefreshing
            ? null
            : () => unawaited(widget.onRetry!());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Md3Card(
        key: const Key('my-movies-refresh-error-banner'),
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.cloud_off_rounded,
                color: Md3Colors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Showing saved movies',
                    style: TextStyle(
                      color: Md3Colors.text,
                      fontSize: 15,
                      height: 1.33,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.refreshError!,
                    maxLines: useCompactLayout ? 2 : null,
                    overflow: useCompactLayout ? TextOverflow.ellipsis : null,
                    style: const TextStyle(
                      color: Md3Colors.muted,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!useCompactLayout && widget.onRetry != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        foregroundColor: Md3Colors.primary,
                      ),
                      onPressed: retry,
                      icon: widget.isRefreshing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Md3Colors.primary,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        widget.isRefreshing ? 'Refreshing' : 'Retry',
                      ),
                    ),
                ],
              ),
            ),
            if (useCompactLayout && widget.onRetry != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: widget.isRefreshing ? 'Refreshing' : 'Retry',
                style: IconButton.styleFrom(
                  foregroundColor: Md3Colors.primary,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: retry,
                icon: widget.isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Md3Colors.primary,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistContent(
    MoviesState moviesState,
    UserState userState,
  ) {
    if (widget.isRefreshing && moviesState.userMovies.isEmpty) {
      return _buildLoadingRows();
    }
    if (widget.refreshError != null && moviesState.userMovies.isEmpty) {
      return _buildTerminalRefreshError();
    }
    if (moviesState.watchlistMovies.isNotEmpty) {
      return MMoviesAnimatedList(
        buildItemFunction: moviesState.buildItem,
        isPremium: userState.isPremium,
        listKey: moviesState.watchlistKey,
        movies: moviesState.watchlistMovies,
        scrollController: _watchlistScrollController,
        padding: EdgeInsets.fromLTRB(
          0,
          4,
          0,
          Md3NavigationMetrics.contentBottomInset(context),
        ),
      );
    }

    return _buildTopAnchoredState(
      scrollController: _watchlistScrollController,
      child: EmptyMoviesCard(
        key: const Key('watchlist-empty-state'),
        title: 'Your Watchlist is empty',
        body: 'Save movies and shows you want to watch.',
        actionText: 'Explore Discover',
        icon: Icons.bookmark_outline_rounded,
        actionIcon: Icons.explore_rounded,
        onAction: widget.onOpenDiscover,
      ),
    );
  }

  Widget _buildViewedContent(
    MoviesState moviesState,
    UserState userState,
    List<Movie> allViewedMovies,
  ) {
    if (widget.isRefreshing && moviesState.userMovies.isEmpty) {
      return _buildLoadingRows();
    }
    if (widget.refreshError != null && moviesState.userMovies.isEmpty) {
      return _buildTerminalRefreshError();
    }
    if (moviesState.viewedMovies.isNotEmpty) {
      return MMoviesAnimatedList(
        buildItemFunction: moviesState.buildItem,
        isPremium: userState.isPremium,
        listKey: moviesState.viewedListKey,
        movies: moviesState.viewedMovies,
        scrollController: _viewedScrollController,
        padding: EdgeInsets.fromLTRB(
          0,
          4,
          0,
          Md3NavigationMetrics.contentBottomInset(context),
        ),
      );
    }
    if (allViewedMovies.isNotEmpty) {
      return _buildFilteredEmptyState(moviesState);
    }

    return _buildTopAnchoredState(
      scrollController: _viewedScrollController,
      child: EmptyMoviesCard(
        key: const Key('viewed-empty-state'),
        title: 'Nothing in Viewed yet',
        body: 'Rate something you’ve seen to start your taste profile.',
        actionText: 'Rate Movies',
        icon: Icons.check_circle_outline_rounded,
        actionIcon: Icons.movie_filter_rounded,
        onAction: widget.onStartRating,
      ),
    );
  }

  Widget _buildLoadingRows() {
    return ListView(
      key: const Key('my-movies-loading-skeleton'),
      padding: EdgeInsets.fromLTRB(
        0,
        4,
        0,
        Md3NavigationMetrics.contentBottomInset(context),
      ),
      children: const [
        Md3ListSkeletonCard(
          rows: 3,
          trailingSize: 44,
        ),
      ],
    );
  }

  Widget _buildTerminalRefreshError() {
    return _buildTopAnchoredState(
      scrollController: _activeTabIndex == 1
          ? _viewedScrollController
          : _watchlistScrollController,
      child: EmptyMoviesCard(
        key: const Key('my-movies-refresh-error-state'),
        title: 'Your library could not refresh',
        body:
            'MovieDiary could not confirm your saved movies. Try again when your connection is available.',
        actionText: widget.isRefreshing ? 'Refreshing' : 'Retry',
        icon: Icons.cloud_off_rounded,
        actionIcon: Icons.refresh_rounded,
        onAction: widget.isRefreshing || widget.onRetry == null
            ? null
            : () => unawaited(widget.onRetry!()),
      ),
    );
  }

  Widget _buildFilteredEmptyState(MoviesState moviesState) {
    final selectedRates = moviesState.selectedRates;
    final label = selectedRates.length == 1
        ? switch (selectedRates.first) {
            MovieRate.liked => 'Liked',
            MovieRate.okay => 'Okay',
            MovieRate.notLiked => 'Disliked',
            _ => 'matching',
          }
        : 'matching';

    return _buildTopAnchoredState(
      scrollController: _viewedScrollController,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Md3Card(
            key: const Key('viewed-filter-empty-state'),
            borderRadius: 20,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Md3Colors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.filter_alt_off_rounded,
                    color: Md3Colors.muted,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No $label ratings yet',
                  style: const TextStyle(
                    color: Md3Colors.text,
                    fontSize: 22,
                    height: 1.23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose another opinion or return to your full Viewed history.',
                  style: TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 15,
                    height: 1.44,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  key: const Key('viewed-filter-show-all'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    foregroundColor: Md3Colors.primary,
                  ),
                  onPressed: moviesState.selectAllViewedRates,
                  icon: const Icon(Icons.filter_list_off_rounded, size: 20),
                  label: const Text(
                    'Show all',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopAnchoredState({
    required Widget child,
    required ScrollController scrollController,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          Md3NavigationMetrics.contentBottomInset(context) + 24,
        ),
        child: child,
      ),
    );
  }
}

class _LibrarySegment extends StatelessWidget {
  final String label;
  final String semanticsLabel;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _LibrarySegment({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Md3Colors.text : Md3Colors.muted;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: semanticsLabel,
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? Md3Colors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: selected
                    ? Border.all(color: Colors.white.withValues(alpha: 0.94))
                    : null,
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x160f253d),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? selectedIcon : icon,
                    color: foreground,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

class _ViewedFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color selectedBackground;
  final Color selectedForeground;
  final VoidCallback onTap;

  const _ViewedFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.selectedBackground,
    required this.selectedForeground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = '$label $count';
    final foreground = selected ? selectedForeground : Md3Colors.text;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label filter, $count titles',
      onTap: onTap,
      excludeSemantics: true,
      child: SizedBox(
        height: 44,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 40,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? selectedBackground : Md3Colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? selectedForeground : Md3Colors.border,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x100f253d),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                text,
                maxLines: 1,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
