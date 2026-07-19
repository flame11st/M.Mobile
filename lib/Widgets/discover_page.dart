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
        18,
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
                  const SizedBox(height: 16),
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
          Md3SectionHeader(
            title: 'Popular Movies',
            actionText: 'Browse Lists',
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
          if (popularMovies.isEmpty)
            _buildEmptyListCard(
              'Popular movies are loading',
              'This section uses released titles with recent MovieDiary activity.',
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
          Md3SectionHeader(
            title: 'Popular TV',
            actionText: 'Browse Lists',
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
          if (popularTv.isEmpty)
            _buildEmptyListCard(
              'Popular TV is loading',
              'This section uses released shows with recent MovieDiary activity.',
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
          Md3SectionHeader(
            title: 'Your Watchlist',
            actionText: 'My Movies',
            onAction: () {},
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
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isReady
                ? 'Start from your taste profile, popular picks, or saved watchlist.'
                : 'Rate movies to teach MovieDiary what fits your taste.',
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 16,
              height: 1.35,
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
    final title = hasProfileError
        ? 'Taste profile unavailable'
        : isReady
            ? 'Taste profile ready'
            : 'Build your taste profile';
    final body = hasProfileError
        ? 'MovieDiary could not load your taste profile from the API. Your ratings are still saved; retry when the service is reachable.'
        : profile?.summaryText?.trim().isNotEmpty == true
            ? profile!.summaryText!
            : isReady
                ? 'MovieDiary has enough ratings to build a recommendation deck.'
                : 'Rate $remaining more movies to unlock sharper recommendations.';
    final ctaText = isReady
        ? 'Get Recommendations'
        : hasStarterMovies
            ? 'Rate Movies'
            : listsRequested
                ? 'Retry Starter Movies'
                : 'Loading Starter Movies';

    return Md3Card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_alt_rounded,
                  color: Md3Colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Md3Colors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                isReady ? '$ratedCount rated' : '$ratedCount/10',
                style: const TextStyle(
                  color: Md3Colors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: const Color(0xffe5e7eb),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Md3Colors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 16,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Md3PrimaryButton(
            text: _isRetryingLists ? 'Loading Starter Movies' : ctaText,
            icon: isReady
                ? Icons.bolt_rounded
                : hasStarterMovies
                    ? Icons.swipe_rounded
                    : Icons.refresh_rounded,
            onPressed: _isRetryingLists
                ? null
                : () {
                    if (!canRate) {
                      _retryStarterMovies(context);
                      return;
                    }

                    if (isReady) {
                      Navigator.of(context).push(
                        RouteHelper.createRoute(
                            () => const RecommendationsPage(autoStart: true)),
                      );
                    } else {
                      _openRatingFlow(context);
                    }
                  },
          ),
          if (!canRate) ...[
            const SizedBox(height: 12),
            Text(
              listsRequested
                  ? 'MovieDiary could not load the starter rating deck. Try again before rating.'
                  : 'MovieDiary is loading the starter rating deck before you begin.',
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (isLoading && ratedCount >= 10) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(minHeight: 3),
          ],
          if (hasProfileError) ...[
            const SizedBox(height: 16),
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
          if (profile != null && _hasTasteProfileDetails(profile)) ...[
            const SizedBox(height: 16),
            if (profile.personalityLabel?.trim().isNotEmpty == true)
              Text(
                profile.personalityLabel!,
                style: const TextStyle(
                  color: Md3Colors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            if (_profilePillars(profile).isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _profilePillars(profile)
                    .take(4)
                    .map((pillar) => Md3Chip(text: pillar))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Md3Colors.primary,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              onPressed: () {
                setState(() {
                  _isTasteProfileExpanded = !_isTasteProfileExpanded;
                });
              },
              icon: Icon(
                _isTasteProfileExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
              ),
              label: Text(
                _isTasteProfileExpanded ? 'Hide details' : 'Show details',
              ),
            ),
            if (_isTasteProfileExpanded) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildProfileMetric(
                      'Confidence',
                      '${profile.profileConfidencePercent}%',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProfileMetric(
                      'Ratings basis',
                      '${profile.movieRatingsCount} movies / ${profile.tvRatingsCount} TV',
                    ),
                  ),
                ],
              ),
              if (profile.favoriteGenres.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildProfileInsight(
                  Icons.theaters_rounded,
                  'Favorite genres',
                  profile.favoriteGenres.take(4).join(', '),
                ),
              ],
              if (profile.preferredDecades.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildProfileInsight(
                  Icons.history_rounded,
                  'Favorite eras',
                  profile.preferredDecades.take(3).join(', '),
                ),
              ],
              if (profile.favoriteThemes.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildProfileInsight(
                  Icons.palette_outlined,
                  'Common themes',
                  profile.favoriteThemes.take(4).join(', '),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildProfileInsight(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Md3Colors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  List<String> _profilePillars(UserTasteProfile profile) {
    if (profile.tastePillars.isNotEmpty) {
      return profile.tastePillars;
    }

    if (profile.favoriteThemes.isNotEmpty) {
      return profile.favoriteThemes;
    }

    return profile.favoriteGenres;
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

  Widget _buildProfileMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff4f6f9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Md3Colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
        !_hasTasteProfileDetails(profile);
  }

  bool _hasTasteProfileDetails(UserTasteProfile profile) {
    return profile.personalityLabel?.trim().isNotEmpty == true ||
        profile.favoriteGenres.isNotEmpty ||
        profile.favoriteThemes.isNotEmpty ||
        profile.tastePillars.isNotEmpty ||
        profile.preferredDecades.isNotEmpty ||
        profile.recommendationAdvice.isNotEmpty;
  }

  UserTasteProfile _cleanTasteProfileForDisplay(UserTasteProfile profile) {
    return UserTasteProfile(
      isReady: profile.isReady,
      isGenerated: profile.isGenerated,
      ratingsCount: profile.ratingsCount,
      favoriteGenres: profile.favoriteGenres,
      dislikedGenres: profile.dislikedGenres,
      favoriteThemes: _cleanLocalTasteList(profile.favoriteThemes),
      tastePillars: _cleanLocalTasteList(profile.tastePillars),
      recommendationAdvice: _cleanLocalTasteList(profile.recommendationAdvice),
      preferredDecades: profile.preferredDecades,
      favoriteDirectors: profile.favoriteDirectors,
      movieRatingsCount: profile.movieRatingsCount,
      tvRatingsCount: profile.tvRatingsCount,
      profileConfidencePercent: profile.profileConfidencePercent,
      isStale: profile.isStale,
      summaryText: profile.summaryText == null
          ? null
          : _cleanLocalTasteText(profile.summaryText!),
      personalityLabel: profile.personalityLabel == null
          ? null
          : _cleanLocalTasteText(profile.personalityLabel!),
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
    final personalityLabel = _localPersonalityLabel(favoriteGenres);
    final pillars = _localTastePillars(
      favoriteGenres,
      preferredDecades,
      movieRatingsCount,
      tvRatingsCount,
    );
    final summaryText = _localTasteSummary(
      favoriteGenres,
      preferredDecades,
      ratedMovies.length,
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
      favoriteThemes: pillars,
      tastePillars: pillars,
      recommendationAdvice: _localRecommendationNotes(
        favoriteGenres,
        dislikedGenres,
        preferredDecades,
      ),
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
          ? apiProfile!.summaryText
          : summaryText,
      personalityLabel: apiProfile?.personalityLabel?.trim().isNotEmpty == true
          ? _cleanLocalTasteText(apiProfile!.personalityLabel!)
          : personalityLabel,
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

  List<String> _localTastePillars(
    List<String> favoriteGenres,
    List<String> preferredDecades,
    int movieRatingsCount,
    int tvRatingsCount,
  ) {
    final pillars = <String>[];

    if (favoriteGenres.isNotEmpty) {
      pillars.add('Often likes ${favoriteGenres.take(2).join(' + ')}');
    }

    if (preferredDecades.isNotEmpty) {
      pillars
          .add('Rates ${preferredDecades.take(2).join(' and ')} titles well');
    }

    if (movieRatingsCount > 0 && tvRatingsCount > 0) {
      pillars.add('Open to movies and TV');
    } else if (movieRatingsCount > 0) {
      pillars.add('Mostly movie-based so far');
    } else if (tvRatingsCount > 0) {
      pillars.add('Mostly TV-based so far');
    }

    if (pillars.isEmpty) {
      pillars.add('Still learning your range');
    }

    return pillars.take(3).toList();
  }

  String _localTasteSummary(
    List<String> favoriteGenres,
    List<String> preferredDecades,
    int ratingsCount,
  ) {
    final genreText = favoriteGenres.isNotEmpty
        ? favoriteGenres.take(2).join(' and ')
        : 'a broad mix';
    final decadeText = preferredDecades.isNotEmpty
        ? ', with ${preferredDecades.take(2).join(' and ')} titles rating well'
        : '';

    return 'MovieDiary has a first read from $ratingsCount ratings: you lean toward $genreText$decadeText.';
  }

  String _localPersonalityLabel(List<String> favoriteGenres) {
    final normalized =
        favoriteGenres.map((genre) => genre.toLowerCase()).toSet();

    if (normalized.contains('drama')) {
      return 'Character-driven taste';
    }

    if (normalized.any((genre) =>
        genre.contains('thriller') ||
        genre.contains('mystery') ||
        genre.contains('crime') ||
        genre.contains('horror'))) {
      return 'Tension-friendly taste';
    }

    if (normalized.any((genre) =>
        genre.contains('science fiction') ||
        genre.contains('sci-fi') ||
        genre.contains('fantasy'))) {
      return 'Imaginative explorer';
    }

    if (normalized.any((genre) =>
        genre.contains('comedy') ||
        genre.contains('romance') ||
        genre.contains('animation'))) {
      return 'Feel-good explorer';
    }

    return 'Taste profile';
  }

  List<String> _localRecommendationNotes(
    List<String> favoriteGenres,
    List<String> dislikedGenres,
    List<String> preferredDecades,
  ) {
    final notes = <String>[];

    if (favoriteGenres.isNotEmpty) {
      notes.add(
          'Recommendations will start close to ${favoriteGenres.take(2).join(' and ')}.');
    }

    if (preferredDecades.isNotEmpty) {
      notes.add(
          'MovieDiary will mix ${preferredDecades.take(2).join(' and ')} with newer options.');
    }

    if (dislikedGenres.isNotEmpty) {
      notes.add(
          'Your dislikes help filter out heavy ${dislikedGenres.take(2).join(' and ')} overlap.');
    }

    if (notes.isEmpty) {
      notes.add('More ratings will make recommendations sharper.');
    }

    return notes.take(3).map(_cleanLocalTasteText).toList();
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
    final signalMatch = RegExp(
      r'^use (.+) as a signal, not a rule\.?$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (signalMatch != null) {
      return 'MovieDiary will treat ${signalMatch.group(1)} as a light preference.';
    }

    final eraPullMatch = RegExp(
      r'^(.+)\s+era pull$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (eraPullMatch != null) {
      return 'Rates ${eraPullMatch.group(1)!.replaceAll('/', 'and')} titles well';
    }

    if (RegExp('adjacent voices', caseSensitive: false).hasMatch(trimmed)) {
      return '';
    }

    var cleaned = trimmed;
    final directorIndex = cleaned.indexOf(' Directors that stand out:');
    if (directorIndex >= 0) {
      cleaned = cleaned.substring(0, directorIndex);
    }

    return cleaned
        .replaceAll(RegExp('future seeker', caseSensitive: false),
            'Imaginative explorer')
        .replaceAll(RegExp('comfort zone', caseSensitive: false), 'favorites')
        .replaceAll(RegExp('era pull', caseSensitive: false), 'era preference')
        .replaceAll(
            RegExp('adjacent voices', caseSensitive: false), 'similar creators')
        .replaceAll(RegExp('signal, not a rule', caseSensitive: false),
            'light preference')
        .trim();
  }

  List<String> _cleanLocalTasteList(List<String> values) {
    return values
        .map(_cleanLocalTasteText)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
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
