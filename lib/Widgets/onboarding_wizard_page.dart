import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Helpers/movie_list_curator.dart';
import 'package:mmobile/Helpers/route_helper.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:mmobile/Widgets/Login.dart';
import 'package:mmobile/Widgets/recommendations_page.dart';
import 'package:provider/provider.dart';

class OnboardingWizardPage extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingWizardPage({
    super.key,
    required this.onFinished,
  });

  @override
  State<OnboardingWizardPage> createState() => _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends State<OnboardingWizardPage> {
  final serviceAgent = ServiceAgent();
  final skippedIds = <String>{};
  int ratedInSession = 0;
  bool isRetryingStarterDeck = false;
  bool isSavingRating = false;

  static const targetRatings = 10;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) {
        return;
      }

      final userState = Provider.of<UserState>(context, listen: false);
      if (userState.onboardingStage != OnboardingStage.rating) {
        userState.setOnboardingStage(OnboardingStage.rating);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final ratedCount = _ratedCount(moviesState);
    final candidates = _candidates(moviesState);
    final profileCount = ratedCount.clamp(0, targetRatings);
    final isComplete = profileCount >= targetRatings;

    if (isComplete) {
      return _buildComplete(profileCount, false);
    }

    if (candidates.isEmpty) {
      return _buildStarterDeckUnavailable(
        moviesState.isStarterDeckRequested ||
            moviesState.isMoviesListsRequested,
        profileCount,
      );
    }

    return _buildRatingStep(candidates.first, profileCount, candidates.length);
  }

  Widget _buildStarterDeckUnavailable(bool listsRequested, int profileCount) {
    if (!listsRequested) {
      return _buildStarterDeckLoading(profileCount);
    }

    return Scaffold(
      backgroundColor: Md3Colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Md3Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: Md3Colors.primary,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Starter movies unavailable',
                          style: TextStyle(
                            color: Md3Colors.text,
                            fontSize: 28,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'MovieDiary could not load enough starter movies for the first rating flow. Try loading the deck again before continuing.',
                          style: TextStyle(
                            color: Md3Colors.muted,
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressCard(profileCount),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomBar(
                primaryText: isRetryingStarterDeck
                    ? 'Loading Starter Movies'
                    : 'Retry Starter Movies',
                primaryIcon: Icons.refresh_rounded,
                onPrimary: isRetryingStarterDeck ? null : _retryStarterDeck,
                secondaryText: 'Go to Discover',
                onSecondary: _finishOnboarding,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarterDeckLoading(int profileCount) {
    return Scaffold(
      backgroundColor: Md3Colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRatingHeader(profileCount),
              const SizedBox(height: 16),
              const Md3Card(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Md3SkeletonBox(width: 112, height: 168, radius: 16),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Md3SkeletonBox(width: 92, height: 28, radius: 14),
                              SizedBox(height: 14),
                              Md3SkeletonBox(height: 24, radius: 10),
                              SizedBox(height: 10),
                              FractionallySizedBox(
                                widthFactor: 0.72,
                                child: Md3SkeletonBox(height: 24, radius: 10),
                              ),
                              SizedBox(height: 18),
                              Md3SkeletonBox(
                                  width: 118, height: 34, radius: 17),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    FractionallySizedBox(
                      widthFactor: 0.66,
                      child: Md3SkeletonBox(height: 16, radius: 8),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Md3SkeletonBox(height: 54, radius: 18)),
                        SizedBox(width: 10),
                        Expanded(child: Md3SkeletonBox(height: 54, radius: 18)),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: Md3SkeletonBox(height: 54, radius: 18)),
                        SizedBox(width: 10),
                        Expanded(child: Md3SkeletonBox(height: 54, radius: 18)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Loading a balanced mix of movies and TV',
                  style: TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStep(Movie movie, int profileCount, int remaining) {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final sourceLabel = _starterSourceLabel(movie, moviesState);

    return Scaffold(
      backgroundColor: Md3Colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRatingHeader(profileCount),
              const SizedBox(height: 16),
              Md3Card(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Md3MoviePoster(
                          movie: movie,
                          width: 112,
                          height: 168,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSourcePill(sourceLabel),
                              const SizedBox(height: 10),
                              Text(
                                movie.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Md3Colors.text,
                                  fontSize: 24,
                                  height: 1.08,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (movie.releaseDate.year > 1)
                                    Md3Chip(
                                        text:
                                            movie.releaseDate.year.toString()),
                                  if (movie.duration > 0)
                                    Md3Chip(text: '${movie.duration} min'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (movie.genres.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        movie.genres.take(3).join(' / '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Md3Colors.muted,
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (movie.overview.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        movie.overview,
                        style: const TextStyle(
                          color: Md3Colors.muted,
                          fontSize: 16,
                          height: 1.36,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildRatingControls(movie),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$remaining left in this starter deck',
                            style: const TextStyle(
                              color: Md3Colors.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Text(
                          'Change later',
                          style: TextStyle(
                            color: Md3Colors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingHeader(int profileCount) {
    final progress = (profileCount / targetRatings).clamp(0.0, 1.0);
    final remaining = (targetRatings - profileCount).clamp(0, targetRatings);

    return Md3Card(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate Movies',
                      style: TextStyle(
                        color: Md3Colors.text,
                        fontSize: 30,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'A few ratings unlock your first taste profile.',
                      style: TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 15,
                        height: 1.32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Onboarding options',
                icon: const Icon(Icons.more_horiz_rounded),
                color: Md3Colors.surface,
                onSelected: (value) {
                  if (value == 'skip') {
                    _skipOnboarding();
                  } else if (value == 'signin') {
                    _openLogin();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'skip',
                    child: Text('Skip for now'),
                  ),
                  PopupMenuItem(
                    value: 'signin',
                    child: Text('Sign in'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '$profileCount/$targetRatings',
                style: const TextStyle(
                  color: Md3Colors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: progress,
                    backgroundColor: Md3Colors.surfaceMuted,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Md3Colors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                remaining == 0 ? 'Ready' : '$remaining left',
                style: const TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplete(int profileCount, bool deckEmpty) {
    if (deckEmpty && profileCount < targetRatings) {
      return _buildStarterDeckUnavailable(true, profileCount);
    }

    return Scaffold(
      backgroundColor: Md3Colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Md3Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Md3Colors.success,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profileCount >= targetRatings
                              ? 'Taste profile ready'
                              : 'Your taste profile has started',
                          style: const TextStyle(
                            color: Md3Colors.text,
                            fontSize: 28,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          deckEmpty
                              ? 'No more starter movies are available right now. Discover will still keep the Rate Movies CTA ready.'
                              : 'We have enough ratings to generate better recommendations.',
                          style: const TextStyle(
                            color: Md3Colors.muted,
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressCard(profileCount),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomBar(
                primaryText: profileCount >= targetRatings
                    ? 'Get Recommendations'
                    : 'Go to Discover',
                primaryIcon: profileCount >= targetRatings
                    ? Icons.bolt_rounded
                    : Icons.explore_rounded,
                onPrimary: profileCount >= targetRatings
                    ? _openRecommendations
                    : _finishOnboarding,
                secondaryText:
                    profileCount >= targetRatings ? 'Go to Discover' : 'Back',
                onSecondary: _finishOnboarding,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(int profileCount) {
    final progress = (profileCount / targetRatings).clamp(0.0, 1.0);
    final remaining = (targetRatings - profileCount).clamp(0, targetRatings);

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
              const Expanded(
                child: Text(
                  'Taste profile',
                  style: TextStyle(
                    color: Md3Colors.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              Text(
                '$profileCount of $targetRatings movies rated',
                style: const TextStyle(
                  color: Md3Colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 10),
          Text(
            remaining == 0
                ? 'Ready for stronger recommendations.'
                : '$remaining more ratings to sharpen recommendations.',
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingControls(Movie movie) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Md3Colors.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Md3Colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _ratingButton(
                  'Liked it',
                  Icons.favorite_rounded,
                  Md3Colors.success,
                  isSavingRating ? null : () => _rate(movie, MovieRate.liked),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ratingButton(
                  'It was okay',
                  Icons.sentiment_satisfied_alt_rounded,
                  Md3Colors.warning,
                  isSavingRating ? null : () => _rate(movie, MovieRate.okay),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ratingButton(
                  "Didn't like it",
                  Icons.block_rounded,
                  Md3Colors.danger,
                  isSavingRating
                      ? null
                      : () => _rate(movie, MovieRate.notLiked),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ratingButton(
                  "Haven't Seen",
                  Icons.skip_next_rounded,
                  Md3Colors.muted,
                  isSavingRating ? null : () => _skip(movie),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourcePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Md3Colors.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xffc9d8ea)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Md3Colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _ratingButton(
      String text, IconData icon, Color color, VoidCallback? onPressed) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar({
    required String primaryText,
    required IconData primaryIcon,
    required VoidCallback? onPrimary,
    required String secondaryText,
    required VoidCallback onSecondary,
  }) {
    return Md3LiquidGlass(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      borderRadius: BorderRadius.circular(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Md3PrimaryButton(
            text: primaryText,
            icon: primaryIcon,
            onPressed: onPrimary,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSecondary,
            child: Text(
              secondaryText,
              style: const TextStyle(
                color: Md3Colors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Movie> _candidates(MoviesState moviesState) {
    final pool = _buildStarterPool(moviesState);
    final seenIds = <String>{};

    return pool
        .where((movie) => seenIds.add(movie.id))
        .where((movie) => !skippedIds.contains(movie.id))
        .where((movie) => !MovieRate.isViewed(movie.movieRate))
        .where(MovieListCurator.isTrustedStarterItem)
        .take(40)
        .toList();
  }

  List<Movie> _buildStarterPool(MoviesState moviesState) {
    if (moviesState.starterDeckMovies.isNotEmpty) {
      return _balanceByEraAndType(moviesState.starterDeckMovies);
    }

    final lists = moviesState.externalMoviesLists;
    final sourceBuckets = <List<Movie>>[
      MovieListCurator.moviesForPurpose(
        lists,
        CuratedMovieListPurpose.popularMovies,
        limit: 20,
      ),
      MovieListCurator.moviesForPurpose(
        lists,
        CuratedMovieListPurpose.popularTv,
        limit: 20,
      ),
      MovieListCurator.moviesForPurpose(
        lists,
        CuratedMovieListPurpose.topRatedMovies,
        limit: 20,
      ),
      MovieListCurator.moviesForPurpose(
        lists,
        CuratedMovieListPurpose.topRatedTv,
        limit: 20,
      ),
      MovieListCurator.moviesForPurpose(
        lists,
        CuratedMovieListPurpose.teamMovies,
        limit: 20,
      ),
      MovieListCurator.moviesForPurpose(
        lists,
        CuratedMovieListPurpose.teamTv,
        limit: 20,
      ),
    ].where((bucket) => bucket.isNotEmpty).toList();

    if (sourceBuckets.isEmpty) {
      sourceBuckets.addAll([
        MovieListCurator.trustedFallbackByType(
          lists,
          MovieType.movie,
          limit: 24,
        ),
        MovieListCurator.trustedFallbackByType(
          lists,
          MovieType.tv,
          limit: 24,
        ),
      ].where((bucket) => bucket.isNotEmpty));
    }

    final interleaved = _interleave(sourceBuckets);
    if (interleaved.isNotEmpty) {
      return _balanceByEraAndType(interleaved);
    }

    return moviesState.watchlistMovies;
  }

  String _starterSourceLabel(Movie movie, MoviesState moviesState) {
    return MovieListCurator.sourceLabelForMovie(
      movie,
      moviesState.externalMoviesLists,
    );
  }

  List<Movie> _interleave(List<List<Movie>> buckets) {
    final result = <Movie>[];
    final maxLength = buckets.fold<int>(
      0,
      (max, bucket) => bucket.length > max ? bucket.length : max,
    );

    for (var index = 0; index < maxLength; index++) {
      for (final bucket in buckets) {
        if (index < bucket.length) {
          result.add(bucket[index]);
        }
      }
    }

    return result;
  }

  List<Movie> _balanceByEraAndType(List<Movie> movies) {
    final recentMovies = <Movie>[];
    final classicMovies = <Movie>[];
    final recentTv = <Movie>[];
    final classicTv = <Movie>[];

    for (final movie in movies) {
      final isClassic = movie.releaseDate.year > 1 &&
          movie.releaseDate.year < DateTime.now().year - 15;

      if (movie.movieType == MovieType.tv) {
        (isClassic ? classicTv : recentTv).add(movie);
      } else {
        (isClassic ? classicMovies : recentMovies).add(movie);
      }
    }

    return _interleave([
      recentMovies,
      recentTv,
      classicMovies,
      classicTv,
    ].where((bucket) => bucket.isNotEmpty).toList());
  }

  int _ratedCount(MoviesState moviesState) {
    return moviesState.userMovies
        .where((movie) => MovieRate.isViewed(movie.movieRate))
        .length;
  }

  Future<void> _rate(Movie movie, int movieRate) async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);

    if (isSavingRating) {
      return;
    }

    setState(() {
      isSavingRating = true;
    });

    try {
      await moviesState.changeMovieRate(
        movie.id,
        movieRate,
        userState.isIncognitoMode,
        movie,
        updateListRatings: false,
      );

      if (!userState.isIncognitoMode &&
          userState.userId != null &&
          userState.userId!.isNotEmpty) {
        unawaited(serviceAgent
            .rateMovie(movie.id, userState.userId!, movieRate)
            .catchError((error) {
          debugPrint('Onboarding rating background sync failed: $error');
          if (mounted) {
            MSnackBar.showSnackBar(
              'Saved here. Sync will retry when the library refreshes.',
              false,
            );
          }
        }));
      }
    } catch (error) {
      debugPrint('Onboarding rating failed: $error');
      if (mounted) {
        setState(() {
          isSavingRating = false;
        });
        MSnackBar.showSnackBar('Could not save that rating. Try again.', false);
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      ratedInSession += 1;
      isSavingRating = false;
    });

    MSnackBar.showSnackBar('"${movie.title}" saved', true);
  }

  void _skip(Movie movie) {
    setState(() {
      skippedIds.add(movie.id);
    });
  }

  Future<void> _finishOnboarding() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final navigator = Navigator.of(context);

    if (_ratedCount(moviesState) >= targetRatings) {
      await userState.setOnboardingCompleted(true);
    } else {
      await userState.setOnboardingSkipped(true);
    }

    if (!mounted) {
      return;
    }

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    widget.onFinished();
  }

  Future<void> _skipOnboarding() async {
    final userState = Provider.of<UserState>(context, listen: false);

    await userState.setOnboardingSkipped(true);

    if (!mounted) {
      return;
    }

    widget.onFinished();
  }

  Future<void> _retryStarterDeck() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final userId = userState.userId;

    if (userId == null || userId.isEmpty || isRetryingStarterDeck) {
      return;
    }

    setState(() {
      isRetryingStarterDeck = true;
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
      debugPrint('Starter deck retry failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          isRetryingStarterDeck = false;
        });
      }
    }
  }

  void _openLogin() {
    Navigator.of(context).push(
      RouteHelper.createRoute(() => const Login()),
    );
  }

  Future<void> _completeIfReadyOtherwiseSkip() {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);

    if (_ratedCount(moviesState) >= targetRatings) {
      return userState.setOnboardingCompleted(true);
    }

    return userState.setOnboardingSkipped(true);
  }

  Future<void> _openRecommendations() async {
    await _completeIfReadyOtherwiseSkip();

    if (!mounted) {
      return;
    }

    final userState = Provider.of<UserState>(context, listen: false);
    if (userState.isIncognitoMode) {
      await _showSaveAndSyncPrompt();

      if (!mounted) {
        return;
      }
    }

    Navigator.of(context).push(
      RouteHelper.createRoute(() => const RecommendationsPage(autoStart: true)),
    );
  }

  Future<void> _showSaveAndSyncPrompt() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Md3LiquidGlass(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Save and sync your movie taste',
                  style: TextStyle(
                    color: Md3Colors.text,
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Create a free account to keep your ratings, watchlist, and recommendations across devices.',
                  style: TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _authPromptButton(
                  sheetContext,
                  'Continue with Apple',
                  Icons.apple_rounded,
                ),
                const SizedBox(height: 8),
                _authPromptButton(
                  sheetContext,
                  'Continue with Google',
                  Icons.g_mobiledata_rounded,
                ),
                const SizedBox(height: 8),
                _authPromptButton(
                  sheetContext,
                  'Email',
                  Icons.mail_rounded,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text(
                      'Not now',
                      style: TextStyle(
                        color: Md3Colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _authPromptButton(
    BuildContext sheetContext,
    String text,
    IconData icon,
  ) {
    return Md3PrimaryButton(
      text: text,
      icon: icon,
      tonal: true,
      onPressed: () {
        Navigator.of(sheetContext).pop();
        Navigator.of(context).push(
          RouteHelper.createRoute(() => const Login()),
        );
      },
    );
  }
}
