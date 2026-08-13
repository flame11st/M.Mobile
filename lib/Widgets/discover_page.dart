import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Helpers/movie_list_curator.dart';
import 'package:mmobile/Helpers/route_helper.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Objects/user_taste_profile.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/movie_list_item_expanded.dart';
import 'package:mmobile/Widgets/movie_dna_profile.dart';
import 'package:mmobile/Widgets/movies_list_page.dart';
import 'package:mmobile/Widgets/onboarding_wizard_page.dart';
import 'package:mmobile/Widgets/recommendations_page.dart';
import 'package:provider/provider.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({
    super.key,
    this.isOffline = false,
    this.isRefreshing = false,
    this.onRetry,
    this.onOpenLists,
    this.onOpenWatchlist,
    this.scrollController,
  });

  final bool isOffline;
  final bool isRefreshing;
  final Future<void> Function()? onRetry;
  final VoidCallback? onOpenLists;
  final VoidCallback? onOpenWatchlist;
  final ScrollController? scrollController;

  @override
  State<DiscoverPage> createState() => DiscoverPageState();
}

class DiscoverPageState extends State<DiscoverPage> {
  final serviceAgent = ServiceAgent();
  final _fallbackScrollController = ScrollController();
  Future<UserTasteProfile>? _profileFuture;
  String? _profileUserId;
  int? _profileRatingsCount;
  bool _isRetryingLists = false;
  bool _isTasteProfileExpanded = false;
  bool _isRatingFlowOpen = false;

  ScrollController get _scrollController =>
      widget.scrollController ?? _fallbackScrollController;

  Future<void> handleActiveTabTap() async {
    if (!_scrollController.hasClients) {
      return;
    }

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _fallbackScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);
    final ratedMovies = moviesState.userMovies
        .where((movie) => MovieRate.isViewed(movie.movieRate))
        .toList();
    final popularMoviesList = MovieListCurator.listForPurpose(
      moviesState.externalMoviesLists,
      CuratedMovieListPurpose.popularMovies,
    );
    final popularTvList = MovieListCurator.listForPurpose(
      moviesState.externalMoviesLists,
      CuratedMovieListPurpose.popularTv,
    );
    final popularMovies = _moviesForPopularSource(
      popularMoviesList,
      CuratedMovieListPurpose.popularMovies,
    );
    final popularTv = _moviesForPopularSource(
      popularTvList,
      CuratedMovieListPurpose.popularTv,
    );
    final watchlistMovies = moviesState.watchlistMovies.take(5).toList();
    final profileFuture = _getProfileFuture(userState, ratedMovies);
    final hasStarterMovies = _hasStarterMovies(moviesState);

    return Md3Page(
      scrollController: _scrollController,
      includeBottomSafeArea: false,
      padding: EdgeInsets.fromLTRB(
        Md3Layout.pageHorizontalInset(context),
        14,
        Md3Layout.pageHorizontalInset(context),
        Md3NavigationMetrics.contentBottomInset(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isOffline) ...[
            _buildOfflineBanner(),
            const SizedBox(height: 12),
          ],
          FutureBuilder<UserTasteProfile>(
            future: profileFuture,
            builder: (context, snapshot) {
              final effectiveRatedCount = _effectiveRatedCount(
                ratedMovies.length,
                userState.cachedRatedMoviesCount,
                snapshot.data,
              );
              final progress = (effectiveRatedCount / 10).clamp(0.0, 1.0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(
                    context,
                    effectiveRatedCount,
                    snapshot.data,
                  ),
                  const SizedBox(height: 10),
                  _buildTasteProfileCard(
                    context,
                    effectiveRatedCount,
                    progress,
                    snapshot.data,
                    snapshot.connectionState == ConnectionState.waiting,
                    snapshot.hasError,
                    hasStarterMovies,
                    moviesState.isMoviesListsRequested,
                  ),
                ],
              );
            },
          ),
          _buildDiscoverSectionHeader(
            title: 'Popular Movies',
            actionText: popularMovies.isEmpty ? null : 'Show all',
            onAction: popularMovies.isEmpty
                ? null
                : () => _openPopularList(
                      context,
                      popularMoviesList!,
                      popularMovies,
                    ),
          ),
          if (popularMovies.isEmpty && !moviesState.isMoviesListsRequested)
            const Md3ListSkeletonCard(
              rows: 2,
              posterWidth: 58,
              posterHeight: 86,
              cardPadding: 12,
              itemSpacing: 12,
              cardMargin: EdgeInsets.zero,
              cardRadius: 24,
            )
          else if (popularMovies.isEmpty)
            _buildPopularSourceState(
              context,
              sourceList: popularMoviesList,
              purpose: CuratedMovieListPurpose.popularMovies,
            )
          else
            ...popularMovies.take(5).map((movie) => Md3HorizontalMovieCard(
                  movie: movie,
                  onTap: () => _openMovie(context, movie),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Md3Colors.muted,
                  ),
                )),
          _buildDiscoverSectionHeader(
            title: 'Popular TV',
            actionText: popularTv.isEmpty ? null : 'Show all',
            onAction: popularTv.isEmpty
                ? null
                : () => _openPopularList(
                      context,
                      popularTvList!,
                      popularTv,
                    ),
          ),
          if (popularTv.isEmpty && !moviesState.isMoviesListsRequested)
            const Md3ListSkeletonCard(
              rows: 2,
              posterWidth: 58,
              posterHeight: 86,
              cardPadding: 12,
              itemSpacing: 12,
              cardMargin: EdgeInsets.zero,
              cardRadius: 24,
            )
          else if (popularTv.isEmpty)
            _buildPopularSourceState(
              context,
              sourceList: popularTvList,
              purpose: CuratedMovieListPurpose.popularTv,
            )
          else
            ...popularTv.take(5).map((movie) => Md3HorizontalMovieCard(
                  movie: movie,
                  onTap: () => _openMovie(context, movie),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Md3Colors.muted,
                  ),
                )),
          _buildDiscoverSectionHeader(
            title: 'Your Watchlist',
            actionText: widget.onOpenWatchlist == null ? null : 'View All',
            actionSemanticsLabel: 'View all Your Watchlist movies',
            onAction: widget.onOpenWatchlist,
            keepInline: true,
          ),
          if (watchlistMovies.isEmpty)
            _buildEmptyListCard(
              'Your watchlist is ready',
              'Add movies from Search or recommendations and they will appear here.',
              Icons.bookmark_add_outlined,
            )
          else
            ...watchlistMovies.map(
              (movie) => Md3HorizontalMovieCard(
                movie: movie,
                onTap: () => _openMovie(context, movie),
                trailing: const Md3OpinionBadge(
                  movieRate: MovieRate.addedToWatchlist,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openPopularList(
    BuildContext context,
    MoviesList sourceList,
    List<Movie> movies,
  ) {
    final routedList = MoviesList(
      name: sourceList.name,
      order: sourceList.order,
      movieListType: sourceList.movieListType,
      sourceKey: sourceList.sourceKey,
      sourceUpdatedAt: sourceList.sourceUpdatedAt,
      listMovies: movies,
    );
    Navigator.of(context).push(
      RouteHelper.createRoute(
        () => MoviesListPage(
          moviesList: routedList,
          backTooltip: 'Back to Discover',
        ),
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    int ratedCount,
    UserTasteProfile? profile,
  ) {
    final isReady = profile?.isReady == true || ratedCount >= 10;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isReady ? 'Discover' : "Find movies you'll love",
            style: const TextStyle(
              color: Md3Colors.text,
              fontSize: 32,
              height: 38 / 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isReady
                ? 'Start a deck, browse real picks, or revisit your saved movies.'
                : 'Rate a few titles, then browse real picks while MovieDiary learns.',
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasteProfileCard(
    BuildContext context,
    int ratedCount,
    double progress,
    UserTasteProfile? profile,
    bool isLoading,
    bool hasProfileError,
    bool hasStarterMovies,
    bool listsRequested,
  ) {
    final remaining = (10 - ratedCount).clamp(0, 10);
    final isReady = profile?.isReady == true || ratedCount >= 10;
    final canRate = isReady || hasStarterMovies;
    final hasDetails =
        isReady && profile != null && _hasTasteProfileDetails(profile);
    final title = isReady
        ? 'Your MovieDNA'
        : hasProfileError
            ? 'Taste profile unavailable'
            : 'Build your taste profile';
    final body = hasProfileError && isReady
        ? 'Based on $ratedCount rated ${ratedCount == 1 ? 'title' : 'titles'}. Connect to refresh your detailed taste signals.'
        : hasProfileError
            ? 'MovieDiary could not refresh your taste profile. Your saved ratings are still here.'
            : isReady
                ? _profileSummary(profile, ratedCount)
                : 'Rate $remaining more ${remaining == 1 ? 'title' : 'titles'} to unlock sharper recommendations.';
    final ctaText = isReady
        ? 'Get Recommendations'
        : hasStarterMovies
            ? 'Rate Movies'
            : listsRequested
                ? 'Retry Starter Movies'
                : 'Loading Starter Movies';

    return Md3Card(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Md3Colors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Md3Colors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Md3Colors.text,
                    fontSize: 20,
                    height: 25 / 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildRatedCountPill(
                isReady ? '$ratedCount rated' : '$ratedCount/10',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 16,
              height: 23 / 16,
            ),
          ),
          if (isReady && profile != null) ...[
            const SizedBox(height: 10),
            MovieDnaTraitPreview(
              insights: profile.insights,
              fallbackLabels: _cleanProfileLabels([
                ...profile.tastePillars,
                ...profile.favoriteThemes,
                ...profile.favoriteGenres,
              ]),
            ),
          ],
          const SizedBox(height: 12),
          if (isReady)
            _buildTasteProfileActionButton(
              text: _isRetryingLists ? 'Loading' : ctaText,
              icon: Icons.bolt_rounded,
              tonal: false,
              fillWidth: true,
              onPressed: _isRetryingLists
                  ? null
                  : () {
                      Navigator.of(context).push(
                        RouteHelper.createRoute(
                          () => const RecommendationsPage(autoStart: true),
                        ),
                      );
                    },
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final actionText = _isRetryingLists ? 'Loading' : ctaText;
                final textScaler = MediaQuery.textScalerOf(context);
                final textDirection = Directionality.of(context);
                final progressLabel = remaining == 0
                    ? 'Ready for a deck'
                    : '$remaining more to unlock';
                final progressPainter = TextPainter(
                  text: TextSpan(
                    text: progressLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  textDirection: textDirection,
                  textScaler: textScaler,
                  maxLines: 1,
                )..layout();
                final actionPainter = TextPainter(
                  text: TextSpan(
                    text: actionText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  textDirection: textDirection,
                  textScaler: textScaler,
                  maxLines: 1,
                )..layout();
                final preferredActionWidth =
                    (actionPainter.width + 50).clamp(112.0, 172.0);
                final useStackedLayout =
                    progressPainter.width + preferredActionWidth + 12 >
                        constraints.maxWidth;
                final action = _buildTasteProfileActionButton(
                  text: actionText,
                  icon: hasStarterMovies
                      ? Icons.swipe_rounded
                      : Icons.refresh_rounded,
                  tonal: true,
                  fillWidth: useStackedLayout,
                  onPressed: _isRetryingLists
                      ? null
                      : () {
                          if (!canRate) {
                            _retryStarterMovies(context);
                            return;
                          }

                          _openRatingFlow(context);
                        },
                );

                if (useStackedLayout) {
                  return Column(
                    key: const Key('taste-progress-action-layout'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCompactProgress(progress, remaining),
                      const SizedBox(height: 12),
                      action,
                    ],
                  );
                }

                return Row(
                  key: const Key('taste-progress-action-layout'),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildCompactProgress(progress, remaining),
                    ),
                    const SizedBox(width: 12),
                    action,
                  ],
                );
              },
            ),
          if (!canRate) ...[
            const SizedBox(height: 10),
            Text(
              listsRequested
                  ? 'MovieDiary could not load the starter rating deck. Try again before rating.'
                  : 'MovieDiary is loading the starter rating deck before you begin.',
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (isReady && !hasDetails) ...[
            const SizedBox(height: 8),
            Text(
              _confidenceLabel(profile, ratedCount: ratedCount),
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (isLoading && ratedCount >= 10) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(
                  Icons.sync_rounded,
                  size: 16,
                  color: Md3Colors.muted,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Refreshing taste details…',
                    style: TextStyle(
                      color: Md3Colors.muted,
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (hasProfileError) ...[
            const SizedBox(height: 12),
            Md3PrimaryButton(
              text: 'Retry Taste Profile',
              icon: Icons.refresh_rounded,
              tonal: true,
              onPressed: () {
                setState(() {
                  _profileFuture = null;
                });
              },
            ),
          ],
          if (hasDetails) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: Md3Colors.border),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _confidenceLabel(profile, ratedCount: ratedCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Md3Colors.primary,
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.only(left: 8),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isTasteProfileExpanded = !_isTasteProfileExpanded;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Taste details'),
                        const SizedBox(width: 4),
                        Icon(
                          _isTasteProfileExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isTasteProfileExpanded)
              profile.insights.isNotEmpty
                  ? MovieDnaDetails(
                      profile: profile,
                      onRateMore: () => _openRatingFlow(context),
                    )
                  : _buildExpandedProfileDetails(profile),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscoverSectionHeader({
    required String title,
    required String? actionText,
    required VoidCallback? onAction,
    String? actionSemanticsLabel,
    bool keepInline = false,
  }) {
    final titleWidget = Semantics(
      header: true,
      child: Text(
        title,
        key: ValueKey('discover-section-title-$title'),
        maxLines: keepInline ? 1 : 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Md3Colors.text,
          fontSize: 24,
          height: 29 / 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final actionWidget = actionText != null && onAction != null
        ? TextButton(
            key: ValueKey('discover-section-action-$title'),
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              foregroundColor: Md3Colors.primary,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(
              actionText,
              semanticsLabel: actionSemanticsLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        var labelsCompete = false;
        if (actionText != null) {
          final titlePainter = TextPainter(
            text: TextSpan(
              text: title,
              style: const TextStyle(
                fontSize: 24,
                height: 29 / 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            textDirection: Directionality.of(context),
            textScaler: textScaler,
            maxLines: 1,
          )..layout();
          final actionPainter = TextPainter(
            text: TextSpan(
              text: actionText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            textDirection: Directionality.of(context),
            textScaler: textScaler,
            maxLines: 1,
          )..layout();
          labelsCompete = titlePainter.width + actionPainter.width + 28 >
              constraints.maxWidth;
        }
        final useStackedLayout = !keepInline && labelsCompete;

        return Padding(
          padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
          child: useStackedLayout
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    if (actionWidget != null) ...[
                      const SizedBox(height: 8),
                      actionWidget,
                    ],
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: titleWidget),
                    if (actionWidget != null) actionWidget,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildRatedCountPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Md3Colors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Md3Colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildCompactProgress(double progress, int remaining) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: progress,
            backgroundColor: const Color(0xffe5e7eb),
            valueColor: const AlwaysStoppedAnimation<Color>(Md3Colors.primary),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          key: const Key('taste-progress-label'),
          remaining == 0 ? 'Ready for a deck' : '$remaining more to unlock',
          style: const TextStyle(
            color: Md3Colors.muted,
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTasteProfileActionButton({
    required String text,
    required IconData icon,
    required bool tonal,
    bool fillWidth = false,
    required VoidCallback? onPressed,
  }) {
    final background = tonal ? Md3Colors.primarySoft : Md3Colors.primary;
    final foreground = tonal ? Md3Colors.primary : Colors.white;
    final button = SizedBox(
      height: 48,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );

    if (fillWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 112, maxWidth: 172),
      child: button,
    );
  }

  Widget _buildExpandedProfileDetails(UserTasteProfile profile) {
    final genres = _cleanProfileLabels(profile.favoriteGenres).take(5).toList();
    final themes = _cleanProfileLabels(
      profile.favoriteThemes,
      maxWords: 5,
      allowNumbers: false,
    ).take(3).toList();
    final decades = _cleanProfileLabels(
      profile.preferredDecades,
      maxWords: 2,
    ).where((value) => RegExp(r'^\d{4}s$').hasMatch(value)).take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (genres.isNotEmpty) _buildProfileDetailGroup('Top genres', genres),
          if (themes.isNotEmpty) ...[
            if (genres.isNotEmpty) const SizedBox(height: 12),
            _buildProfileDetailGroup('Story and mood', themes),
          ],
          if (decades.isNotEmpty) ...[
            if (genres.isNotEmpty || themes.isNotEmpty)
              const SizedBox(height: 12),
            _buildProfileDetailGroup('Eras you rate highly', decades),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.data_usage_rounded,
                size: 17,
                color: Md3Colors.muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _ratingsBasis(profile),
                  style: const TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Md3Colors.primary,
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                onPressed: () => _openRatingFlow(context),
                child: const Text('Rate more'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailGroup(String label, List<String> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Md3Colors.text,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: values.map((value) => Md3Chip(text: value)).toList(),
        ),
      ],
    );
  }

  String _confidenceLabel(
    UserTasteProfile? profile, {
    required int ratedCount,
  }) {
    if (profile == null || profile.profileConfidencePercent <= 0) {
      return 'Early read · $ratedCount ratings';
    }

    final confidence = profile.profileConfidencePercent;
    if (confidence >= 85) {
      return 'Strong read · $confidence%';
    }
    if (confidence >= 65) {
      return 'Developing read · $confidence%';
    }
    return 'Early read · $confidence%';
  }

  String _ratingsBasis(UserTasteProfile profile) {
    final parts = <String>[];
    if (profile.movieRatingsCount > 0) {
      parts.add(
        '${profile.movieRatingsCount} ${profile.movieRatingsCount == 1 ? 'movie' : 'movies'}',
      );
    }
    if (profile.tvRatingsCount > 0) {
      parts.add(
        '${profile.tvRatingsCount} TV ${profile.tvRatingsCount == 1 ? 'show' : 'shows'}',
      );
    }

    final basis = parts.isEmpty
        ? '${profile.ratingsCount} rated ${profile.ratingsCount == 1 ? 'title' : 'titles'}'
        : parts.join(' and ');
    return 'Based on $basis. More varied ratings make this read sharper.';
  }

  String _profileSummary(UserTasteProfile? profile, int ratedCount) {
    final providedSummary = profile?.summaryText == null
        ? ''
        : _cleanLocalTasteText(profile!.summaryText!);
    if (providedSummary.isNotEmpty && providedSummary.length <= 140) {
      return providedSummary;
    }

    final genres = profile == null
        ? const <String>[]
        : _cleanProfileLabels(profile.favoriteGenres).take(2).toList();
    if (genres.isNotEmpty) {
      return 'Your ratings favor ${genres.join(' and ')}. This profile sharpens as you rate more.';
    }

    return 'Built from $ratedCount ratings. More variety sharpens your recommendations.';
  }

  List<String> _cleanProfileLabels(
    Iterable<String> values, {
    int maxWords = 4,
    bool allowNumbers = true,
  }) {
    return values
        .map(_cleanLocalTasteText)
        .where((value) => value.isNotEmpty)
        .where((value) => value.length <= 40)
        .where((value) =>
            value
                .split(RegExp(r'\s+'))
                .where((word) => word.isNotEmpty)
                .length <=
            maxWords)
        .where((value) => allowNumbers || !RegExp(r'\d').hasMatch(value))
        .toSet()
        .toList();
  }

  int _effectiveRatedCount(
    int localRatedCount,
    int? cachedRatedCount,
    UserTasteProfile? profile,
  ) {
    final localOrCached =
        cachedRatedCount != null && cachedRatedCount > localRatedCount
            ? cachedRatedCount
            : localRatedCount;
    if (profile == null) {
      return localOrCached;
    }

    final profileRatedCount = profile.ratingsCount > 0
        ? profile.ratingsCount
        : profile.movieRatingsCount + profile.tvRatingsCount;

    return profileRatedCount > localOrCached
        ? profileRatedCount
        : localOrCached;
  }

  Widget _buildOfflineBanner() {
    return Semantics(
      liveRegion: true,
      label: 'You are offline. Your saved movies are still here.',
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        decoration: BoxDecoration(
          color: const Color(0xfffff7e8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Md3Colors.warning.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 20,
              color: Md3Colors.warning,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "You're offline. Your saved movies are still here.",
                style: TextStyle(
                  color: Md3Colors.warning,
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                tooltip: 'Retry connection',
                onPressed: widget.isRefreshing || widget.onRetry == null
                    ? null
                    : widget.onRetry,
                icon: widget.isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Md3Colors.warning,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: Md3Colors.warning,
                        size: 21,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<UserTasteProfile>? _getProfileFuture(
    UserState userState,
    List<Movie> ratedMovies,
  ) {
    final userId = userState.userId;
    if (userId == null || userId.isEmpty) {
      return null;
    }

    final ratingsCount = ratedMovies.length;
    if (_isRatingFlowOpen && _profileFuture != null) {
      return _profileFuture;
    }
    if (_profileFuture == null ||
        _profileUserId != userId ||
        _profileRatingsCount != ratingsCount) {
      _profileUserId = userId;
      _profileRatingsCount = ratingsCount;
      _profileFuture = _loadTasteProfile(userId, ratedMovies);
    }

    return _profileFuture;
  }

  Future<UserTasteProfile> _loadTasteProfile(
    String userId,
    List<Movie> ratedMovies,
  ) async {
    try {
      final profile = _cleanTasteProfileForDisplay(
          await serviceAgent.getUserTasteProfile(userId));
      if (_shouldUseLocalProfileFallback(profile, ratedMovies)) {
        return _buildLocalTasteProfile(ratedMovies, profile);
      }

      return profile;
    } catch (error) {
      if (ratedMovies.length >= 10) {
        return _buildLocalTasteProfile(ratedMovies, null);
      }

      rethrow;
    }
  }

  bool _shouldUseLocalProfileFallback(
    UserTasteProfile profile,
    List<Movie> ratedMovies,
  ) {
    if (ratedMovies.length < 10) {
      return false;
    }

    return !profile.isGenerated ||
        profile.summaryText?.trim().isNotEmpty != true ||
        (profile.insights.isEmpty &&
            profile.favoriteGenres.isEmpty &&
            profile.favoriteThemes.isEmpty &&
            profile.preferredDecades.isEmpty);
  }

  bool _hasTasteProfileDetails(UserTasteProfile profile) {
    return profile.favoriteGenres.isNotEmpty ||
        profile.insights.isNotEmpty ||
        profile.recommendationAdvice.isNotEmpty ||
        profile.favoriteThemes.isNotEmpty ||
        profile.preferredDecades.isNotEmpty ||
        profile.movieRatingsCount > 0 ||
        profile.tvRatingsCount > 0;
  }

  UserTasteProfile _cleanTasteProfileForDisplay(UserTasteProfile profile) {
    return UserTasteProfile(
      isReady: profile.isReady,
      isGenerated: profile.isGenerated,
      ratingsCount: profile.ratingsCount,
      favoriteGenres: _cleanProfileLabels(profile.favoriteGenres),
      dislikedGenres: _cleanProfileLabels(profile.dislikedGenres),
      favoriteThemes: _cleanProfileLabels(
        profile.favoriteThemes,
        maxWords: 5,
        allowNumbers: false,
      ),
      tastePillars: _cleanProfileLabels(
        profile.tastePillars,
        maxWords: 5,
        allowNumbers: false,
      ),
      recommendationAdvice: profile.recommendationAdvice
          .map(_cleanLocalTasteText)
          .where((value) => value.isNotEmpty && value.length <= 160)
          .take(3)
          .toList(),
      preferredDecades: _cleanProfileLabels(
        profile.preferredDecades,
        maxWords: 2,
      ).where((value) => RegExp(r'^\d{4}s$').hasMatch(value)).toList(),
      favoriteDirectors: profile.favoriteDirectors,
      insights: _cleanMovieDnaInsights(profile.insights),
      movieRatingsCount: profile.movieRatingsCount,
      tvRatingsCount: profile.tvRatingsCount,
      profileConfidencePercent: profile.profileConfidencePercent,
      isStale: profile.isStale,
      summaryText: profile.summaryText == null
          ? null
          : _cleanLocalTasteText(profile.summaryText!),
      personalityLabel: profile.profileConfidencePercent >= 85
          ? _cleanLocalTasteText(profile.personalityLabel ?? '')
          : null,
      generatedAt: profile.generatedAt,
    );
  }

  UserTasteProfile _buildLocalTasteProfile(
    List<Movie> ratedMovies,
    UserTasteProfile? apiProfile,
  ) {
    final likedMovies = ratedMovies
        .where((movie) => movie.movieRate == MovieRate.liked)
        .toList();
    final okayMovies = ratedMovies
        .where((movie) => movie.movieRate == MovieRate.okay)
        .toList();
    final dislikedMovies = ratedMovies
        .where((movie) => movie.movieRate == MovieRate.notLiked)
        .toList();
    final favoriteGenres = _topWeightedGenres(likedMovies, okayMovies);
    final dislikedGenres = _topGenres(dislikedMovies);
    final preferredDecades = _topWeightedDecades(likedMovies, okayMovies);
    final movieRatingsCount =
        ratedMovies.where((movie) => movie.movieType == MovieType.movie).length;
    final tvRatingsCount =
        ratedMovies.where((movie) => movie.movieType == MovieType.tv).length;
    final summaryText = _localTasteSummary(
      favoriteGenres,
      preferredDecades,
    );

    return UserTasteProfile(
      isReady: true,
      isGenerated: true,
      ratingsCount: ratedMovies.length,
      favoriteGenres: favoriteGenres.isNotEmpty
          ? favoriteGenres
          : apiProfile?.favoriteGenres ?? const [],
      dislikedGenres: dislikedGenres.isNotEmpty
          ? dislikedGenres
          : apiProfile?.dislikedGenres ?? const [],
      favoriteThemes: apiProfile?.favoriteThemes ?? const [],
      tastePillars: apiProfile?.tastePillars ?? const [],
      recommendationAdvice: apiProfile?.recommendationAdvice ?? const [],
      preferredDecades: preferredDecades.isNotEmpty
          ? preferredDecades
          : apiProfile?.preferredDecades ?? const [],
      favoriteDirectors: apiProfile?.favoriteDirectors ?? const [],
      insights: apiProfile == null
          ? const []
          : _cleanMovieDnaInsights(apiProfile.insights),
      movieRatingsCount: movieRatingsCount,
      tvRatingsCount: tvRatingsCount,
      profileConfidencePercent:
          apiProfile?.profileConfidencePercent ?? _localConfidence(ratedMovies),
      isStale: apiProfile?.isStale ?? false,
      summaryText: apiProfile?.summaryText?.trim().isNotEmpty == true
          ? _cleanLocalTasteText(apiProfile!.summaryText!)
          : summaryText,
      personalityLabel: null,
      generatedAt: apiProfile?.generatedAt,
    );
  }

  List<MovieDnaInsight> _cleanMovieDnaInsights(
    Iterable<MovieDnaInsight> insights,
  ) {
    return insights
        .where((insight) => insight.key.isNotEmpty)
        .map((insight) {
          final label = _cleanLocalTasteText(insight.label);
          final description = _cleanLocalTasteText(insight.description);
          final supportingTitles = insight.supportingTitles
              .map(_cleanLocalTasteText)
              .where((title) => title.isNotEmpty && title.length <= 80)
              .take(3)
              .toList();
          return MovieDnaInsight(
            key: insight.key,
            label: label,
            description: description,
            category: insight.category,
            confidencePercent: insight.confidencePercent.clamp(0, 100),
            positiveEvidenceCount: insight.positiveEvidenceCount,
            counterEvidenceCount: insight.counterEvidenceCount,
            supportingTitleIds: insight.supportingTitleIds.take(3).toList(),
            supportingTitles: supportingTitles,
          );
        })
        .where((insight) =>
            insight.label.isNotEmpty &&
            insight.label.length <= 40 &&
            insight.label.split(RegExp(r'\s+')).length <= 5 &&
            insight.description.isNotEmpty &&
            insight.description.length <= 160 &&
            insight.positiveEvidenceCount >= 3 &&
            insight.positiveEvidenceCount > insight.counterEvidenceCount &&
            insight.confidencePercent >= 45)
        .take(5)
        .toList();
  }

  List<String> _topWeightedGenres(
    List<Movie> likedMovies,
    List<Movie> okayMovies,
  ) {
    final scores = <String, int>{};
    _addGenreScores(scores, likedMovies, 3);
    _addGenreScores(scores, okayMovies, 1);

    return _rankScores(scores, 5);
  }

  List<String> _topGenres(List<Movie> movies) {
    final scores = <String, int>{};
    _addGenreScores(scores, movies, 1);

    return _rankScores(scores, 5);
  }

  void _addGenreScores(
    Map<String, int> scores,
    Iterable<Movie> movies,
    int weight,
  ) {
    for (final movie in movies) {
      for (final genre in movie.genres) {
        final cleanGenre = genre.trim();
        if (cleanGenre.isEmpty) {
          continue;
        }

        scores[cleanGenre] = (scores[cleanGenre] ?? 0) + weight;
      }
    }
  }

  List<String> _topWeightedDecades(
    List<Movie> likedMovies,
    List<Movie> okayMovies,
  ) {
    final scores = <String, int>{};
    _addDecadeScores(scores, likedMovies, 3);
    _addDecadeScores(scores, okayMovies, 1);

    return _rankScores(scores, 3);
  }

  void _addDecadeScores(
    Map<String, int> scores,
    Iterable<Movie> movies,
    int weight,
  ) {
    for (final movie in movies) {
      final year = movie.releaseDate.year;
      if (year <= 1) {
        continue;
      }

      final decade = '${year ~/ 10 * 10}s';
      scores[decade] = (scores[decade] ?? 0) + weight;
    }
  }

  List<String> _rankScores(Map<String, int> scores, int count) {
    final ranked = scores.entries.toList()
      ..sort((a, b) {
        final scoreCompare = b.value.compareTo(a.value);
        if (scoreCompare != 0) {
          return scoreCompare;
        }

        return a.key.compareTo(b.key);
      });

    return ranked.take(count).map((entry) => entry.key).toList();
  }

  String _localTasteSummary(
    List<String> favoriteGenres,
    List<String> preferredDecades,
  ) {
    final genreText = favoriteGenres.isNotEmpty
        ? favoriteGenres.take(2).join(' and ')
        : 'a broad mix';
    final decadeText = preferredDecades.isNotEmpty
        ? ', with ${preferredDecades.take(2).join(' and ')} titles rating well'
        : '';

    return 'Your MovieDNA currently leans toward $genreText$decadeText.';
  }

  int _localConfidence(List<Movie> ratedMovies) {
    if (ratedMovies.length >= 25) {
      return 88;
    }

    if (ratedMovies.length >= 15) {
      return 76;
    }

    return 64;
  }

  String _cleanLocalTasteText(String value) {
    final trimmed = value.trim();
    final internalPhrases = [
      'adjacent voices',
      'era pull',
      'future seeker',
      'signal, not a rule',
      'as a signal',
      'prompt',
      'personality type',
      'religion',
      'religious',
      'ethnicity',
      'racial identity',
      'sexuality',
      'gender identity',
      'political identity',
      'medical diagnosis',
      'disability',
      'income level',
    ];
    if (internalPhrases.any(
      (phrase) => trimmed.toLowerCase().contains(phrase),
    )) {
      return '';
    }

    var cleaned = trimmed;
    final directorIndex = cleaned.indexOf(' Directors that stand out:');
    if (directorIndex >= 0) {
      cleaned = cleaned.substring(0, directorIndex);
    }

    return cleaned
        .replaceAll(RegExp('comfort zone', caseSensitive: false), 'favorites')
        .trim();
  }

  Widget _buildEmptyListCard(String title, String body, IconData icon) {
    return Md3Card(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: Md3Colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Md3Colors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Movie> _moviesForPopularSource(
    MoviesList? sourceList,
    CuratedMovieListPurpose purpose,
  ) {
    if (sourceList == null ||
        MovieListCurator.isStalePopularSource(sourceList)) {
      return const [];
    }

    return MovieListCurator.moviesFromListForPurpose(
      sourceList,
      purpose,
      limit: 100,
    );
  }

  Widget _buildPopularSourceState(
    BuildContext context, {
    required MoviesList? sourceList,
    required CuratedMovieListPurpose purpose,
  }) {
    final isTv = purpose == CuratedMovieListPurpose.popularTv;
    final kind = isTv ? 'TV shows' : 'movies';
    final isStale =
        sourceList != null && MovieListCurator.isStalePopularSource(sourceList);
    final title = isStale
        ? 'TMDb $kind need refresh'
        : sourceList == null
            ? 'TMDb $kind unavailable'
            : 'TMDb $kind list is empty';
    final body = isStale
        ? 'Refresh for the latest TMDb list.'
        : sourceList == null
            ? 'The current TMDb list was not returned. MovieDiary alternatives stay separate.'
            : 'TMDb returned no titles. Refresh to check again.';
    final isRefreshing = widget.isRefreshing || _isRetryingLists;

    return Md3Card(
      key: ValueKey('discover-popular-source-state-${isTv ? 'tv' : 'movies'}'),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Md3Colors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(
              isTv ? Icons.live_tv_outlined : Icons.local_movies_outlined,
              color: Md3Colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Md3Colors.text,
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  maxLines: 3,
                  style: const TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: isTv ? 'Retry popular TV' : 'Retry popular movies',
            child: TextButton(
              key: ValueKey(
                'discover-popular-retry-${isTv ? 'tv' : 'movies'}',
              ),
              onPressed:
                  isRefreshing ? null : () => _retryPopularSources(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: Md3Colors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: isRefreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _retryPopularSources(BuildContext context) async {
    if (widget.isRefreshing || _isRetryingLists) {
      return;
    }

    final retry = widget.onRetry;
    if (retry != null) {
      await retry();
      return;
    }

    await _retryStarterMovies(context);
  }

  bool _hasStarterMovies(MoviesState moviesState) {
    return moviesState.externalMoviesLists
            .any((list) => list.listMovies.isNotEmpty) ||
        moviesState.watchlistMovies.isNotEmpty ||
        moviesState.userMovies.isNotEmpty;
  }

  Future<void> _retryStarterMovies(BuildContext context) async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final userId = userState.userId;

    if (userId == null || userId.isEmpty || _isRetryingLists) {
      return;
    }

    setState(() {
      _isRetryingLists = true;
    });

    try {
      final response = await serviceAgent.getMoviesLists(userId);
      final decodedBody = json.decode(response.body);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decodedBody is! Iterable) {
        throw const FormatException('Starter movie list response was invalid.');
      }

      final moviesLists = decodedBody.map((model) {
        return MoviesList.fromJson(json.decode(model));
      }).toList();

      if (userState.isIncognitoMode) {
        await moviesState.setInitialMoviesListsIncognito(moviesLists);
      } else {
        await moviesState.setInitialMoviesLists(moviesLists);
      }
    } catch (error) {
      debugPrint('Starter movie retry failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isRetryingLists = false;
        });
      }
    }
  }

  void _openMovie(BuildContext context, Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MovieListItemExpanded(
          movie: movie,
          imageUrl: 'https://moviediarystorage.blob.core.windows.net/movies',
        ),
      ),
    );
  }

  Future<void> _openRatingFlow(BuildContext context) async {
    if (_isRatingFlowOpen) {
      return;
    }

    setState(() {
      _isRatingFlowOpen = true;
    });

    try {
      await Navigator.of(context).push(
        RouteHelper.createRoute(
          () => OnboardingWizardPage(
            mode: RatingFlowMode.continuous,
            onFinished: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRatingFlowOpen = false;
          _profileFuture = null;
          _profileRatingsCount = null;
        });
      }
    }
  }
}
