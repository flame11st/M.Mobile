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
import 'package:mmobile/Widgets/movies_lists_page.dart';
import 'package:mmobile/Widgets/onboarding_wizard_page.dart';
import 'package:mmobile/Widgets/recommendations_page.dart';
import 'package:provider/provider.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final serviceAgent = ServiceAgent();
  Future<UserTasteProfile>? _profileFuture;
  String? _profileUserId;
  int? _profileRatingsCount;
  bool _isRetryingLists = false;
  bool _isTasteProfileExpanded = false;

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);
    final ratedMovies = moviesState.userMovies
        .where((movie) => MovieRate.isViewed(movie.movieRate))
        .toList();
    final popularMovies = _popularBySource(
      moviesState,
      purpose: CuratedMovieListPurpose.popularMovies,
      fallbackType: MovieType.movie,
    );
    final popularTv = _popularBySource(
      moviesState,
      purpose: CuratedMovieListPurpose.popularTv,
      fallbackType: MovieType.tv,
    );
    final watchlistMovies = moviesState.watchlistMovies.take(3).toList();
    final profileFuture = _getProfileFuture(userState, ratedMovies);
    final hasStarterMovies = _hasStarterMovies(moviesState);

    return Md3Page(
      includeBottomSafeArea: false,
      padding: EdgeInsets.fromLTRB(
        18,
        14,
        18,
        Md3NavigationMetrics.contentBottomInset(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<UserTasteProfile>(
            future: profileFuture,
            builder: (context, snapshot) {
              final effectiveRatedCount = _effectiveRatedCount(
                ratedMovies.length,
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
            actionText: 'Open General Lists',
            onAction: () => Navigator.of(context).push(
              RouteHelper.createRoute(
                () => const MoviesListsPage(initialPageIndex: 0),
              ),
            ),
          ),
          _buildSourceNote(
            MovieListCurator.sourceNoteForPurpose(
              CuratedMovieListPurpose.popularMovies,
            ),
          ),
          if (popularMovies.isEmpty && !moviesState.isMoviesListsRequested)
            const Md3ListSkeletonCard(
              rows: 2,
              posterWidth: 58,
              posterHeight: 86,
              cardPadding: 12,
              itemSpacing: 12,
            )
          else if (popularMovies.isEmpty)
            _buildEmptyListCard(
              'Popular movies unavailable',
              'MovieDiary could not load this section from the API. Try General Lists or Search while it reconnects.',
              Icons.local_movies_outlined,
            )
          else
            ...popularMovies.take(4).map((movie) => Md3HorizontalMovieCard(
                  movie: movie,
                  onTap: () => _openMovie(context, movie),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Md3Colors.muted,
                  ),
                )),
          _buildDiscoverSectionHeader(
            title: 'Popular TV',
            actionText: 'Open General Lists',
            onAction: () => Navigator.of(context).push(
              RouteHelper.createRoute(
                () => const MoviesListsPage(initialPageIndex: 0),
              ),
            ),
          ),
          _buildSourceNote(
            MovieListCurator.sourceNoteForPurpose(
              CuratedMovieListPurpose.popularTv,
            ),
          ),
          if (popularTv.isEmpty && !moviesState.isMoviesListsRequested)
            const Md3ListSkeletonCard(
              rows: 2,
              posterWidth: 58,
              posterHeight: 86,
              cardPadding: 12,
              itemSpacing: 12,
            )
          else if (popularTv.isEmpty)
            _buildEmptyListCard(
              'Popular TV unavailable',
              'MovieDiary could not load this section from the API. Try General Lists or Search while it reconnects.',
              Icons.live_tv_outlined,
            )
          else
            ...popularTv.take(4).map((movie) => Md3HorizontalMovieCard(
                  movie: movie,
                  onTap: () => _openMovie(context, movie),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Md3Colors.muted,
                  ),
                )),
          _buildDiscoverSectionHeader(
            title: 'Your Watchlist',
            actionText: null,
            onAction: null,
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
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w900,
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
    final title = hasProfileError
        ? 'Taste profile unavailable'
        : isReady
            ? 'Your taste profile'
            : 'Build your taste profile';
    final body = hasProfileError
        ? 'MovieDiary could not load your taste profile from the API. Your ratings are still saved; retry when the service is reachable.'
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
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
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
            maxLines: hasProfileError ? 4 : 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          if (isReady)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (profile != null)
                  Expanded(
                    child: Text(
                      _confidenceLabel(profile),
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 10),
                _buildTasteProfileActionButton(
                  text: _isRetryingLists ? 'Loading' : ctaText,
                  icon: Icons.bolt_rounded,
                  tonal: false,
                  onPressed: _isRetryingLists
                      ? null
                      : () {
                          Navigator.of(context).push(
                            RouteHelper.createRoute(
                              () => const RecommendationsPage(autoStart: true),
                            ),
                          );
                        },
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildCompactProgress(progress, remaining)),
                const SizedBox(width: 12),
                _buildTasteProfileActionButton(
                  text: _isRetryingLists ? 'Loading' : ctaText,
                  icon: hasStarterMovies
                      ? Icons.swipe_rounded
                      : Icons.refresh_rounded,
                  tonal: true,
                  onPressed: _isRetryingLists
                      ? null
                      : () {
                          if (!canRate) {
                            _retryStarterMovies(context);
                            return;
                          }

                          _openRatingFlow(context);
                        },
                ),
              ],
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
          if (isLoading && ratedCount >= 10) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(minHeight: 3),
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
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Md3Colors.primary,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isTasteProfileExpanded = !_isTasteProfileExpanded;
                  });
                },
                child: Row(
                  children: [
                    const Expanded(child: Text('Taste details')),
                    Icon(
                      _isTasteProfileExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_isTasteProfileExpanded) _buildExpandedProfileDetails(profile),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscoverSectionHeader({
    required String title,
    required String? actionText,
    required VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Md3Colors.text,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: Md3Colors.primary,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(actionText),
            ),
        ],
      ),
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
    required VoidCallback? onPressed,
  }) {
    final background = tonal ? Md3Colors.primarySoft : Md3Colors.primary;
    final foreground = tonal ? Md3Colors.primary : Colors.white;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 112, maxWidth: 172),
      child: SizedBox(
        height: 42,
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
      ),
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
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  String _confidenceLabel(UserTasteProfile profile) {
    if (profile.profileConfidencePercent >= 85 || profile.ratingsCount >= 25) {
      return 'Well-defined';
    }

    if (profile.profileConfidencePercent >= 70 || profile.ratingsCount >= 15) {
      return 'Taking shape';
    }

    return 'Early read';
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
    if (providedSummary.isNotEmpty && providedSummary.length <= 130) {
      return providedSummary;
    }

    final genres = profile == null
        ? const <String>[]
        : _cleanProfileLabels(profile.favoriteGenres).take(2).toList();
    if (genres.isNotEmpty) {
      return 'Your ratings point to ${genres.join(' and ')}. This profile will keep refining as you rate more.';
    }

    return 'Built from $ratedCount ratings. Rate a wider mix to make your recommendations more precise.';
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

  int _effectiveRatedCount(int localRatedCount, UserTasteProfile? profile) {
    if (profile == null) {
      return localRatedCount;
    }

    final profileRatedCount = profile.ratingsCount > 0
        ? profile.ratingsCount
        : profile.movieRatingsCount + profile.tvRatingsCount;

    return profileRatedCount > localRatedCount
        ? profileRatedCount
        : localRatedCount;
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
        (profile.favoriteGenres.isEmpty &&
            profile.favoriteThemes.isEmpty &&
            profile.preferredDecades.isEmpty);
  }

  bool _hasTasteProfileDetails(UserTasteProfile profile) {
    return profile.favoriteGenres.isNotEmpty ||
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
      tastePillars: const [],
      recommendationAdvice: const [],
      preferredDecades: _cleanProfileLabels(
        profile.preferredDecades,
        maxWords: 2,
      ).where((value) => RegExp(r'^\d{4}s$').hasMatch(value)).toList(),
      favoriteDirectors: profile.favoriteDirectors,
      movieRatingsCount: profile.movieRatingsCount,
      tvRatingsCount: profile.tvRatingsCount,
      profileConfidencePercent: profile.profileConfidencePercent,
      isStale: profile.isStale,
      summaryText: profile.summaryText == null
          ? null
          : _cleanLocalTasteText(profile.summaryText!),
      personalityLabel: null,
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
      tastePillars: const [],
      recommendationAdvice: const [],
      preferredDecades: preferredDecades.isNotEmpty
          ? preferredDecades
          : apiProfile?.preferredDecades ?? const [],
      favoriteDirectors: apiProfile?.favoriteDirectors ?? const [],
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

    return 'Your ratings point to $genreText$decadeText.';
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

  Widget _buildSourceNote(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
      child: Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 16,
            color: Md3Colors.muted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Movie> _popularBySource(
    MoviesState moviesState, {
    required CuratedMovieListPurpose purpose,
    required MovieType fallbackType,
  }) {
    final curatedMovies = MovieListCurator.moviesForPurpose(
      moviesState.externalMoviesLists,
      purpose,
      limit: 12,
    );

    if (curatedMovies.isNotEmpty) {
      return curatedMovies;
    }

    return MovieListCurator.trustedFallbackByType(
      moviesState.externalMoviesLists,
      fallbackType,
      limit: 12,
    );
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

  void _openRatingFlow(BuildContext context) {
    Navigator.of(context).push(
      RouteHelper.createRoute(
        () => OnboardingWizardPage(
          onFinished: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
