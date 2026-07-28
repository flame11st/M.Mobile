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
  final VoidCallback? onExitStarted;
  final VoidCallback? onExitCompleted;
  final WidgetBuilder? recommendationsBuilder;

  const OnboardingWizardPage({
    super.key,
    required this.onFinished,
    this.onExitStarted,
    this.onExitCompleted,
    this.recommendationsBuilder,
  });

  @override
  State<OnboardingWizardPage> createState() => _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends State<OnboardingWizardPage> {
  final serviceAgent = ServiceAgent();
  final skippedIds = <String>{};
  final ScrollController _scrollController = ScrollController();
  bool isRetryingStarterDeck = false;
  bool isSavingRating = false;
  bool isCompleting = false;
  String? _expandedSynopsisMovieId;

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
              padding: EdgeInsets.fromLTRB(
                Md3Layout.pageHorizontalInset(context),
                18,
                Md3Layout.pageHorizontalInset(context),
                132,
              ),
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
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isCompact = viewportWidth <= 390;
    final posterWidth = isCompact ? 92.0 : 112.0;
    final posterHeight = isCompact ? 138.0 : 168.0;
    final trayClearance = textScale >= 1.6 ? 184.0 : 160.0;
    final synopsisExpanded = _expandedSynopsisMovieId == movie.id;

    return Scaffold(
      backgroundColor: Md3Colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(16, 8, 16, trayClearance),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRatingHeader(profileCount),
                  const SizedBox(height: 16),
                  KeyedSubtree(
                    key: ValueKey(movie.id),
                    child: Md3Card(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Md3MoviePoster(
                                movie: movie,
                                width: posterWidth,
                                height: posterHeight,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSourcePill(sourceLabel),
                                    const SizedBox(height: 8),
                                    Text(
                                      movie.title,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Md3Colors.text,
                                        fontSize: isCompact ? 21 : 24,
                                        height: isCompact ? 1.19 : 1.08,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _candidateMetadata(movie),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Md3Colors.muted,
                                        fontSize: 13,
                                        height: 1.38,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (movie.genres.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              movie.genres.take(4).join(' / '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Md3Colors.muted,
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          if (movie.overview.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            AnimatedSize(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: Text(
                                movie.overview,
                                maxLines: synopsisExpanded ? null : 3,
                                overflow: synopsisExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Md3Colors.muted,
                                  fontSize: 15,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(44, 44),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _expandedSynopsisMovieId =
                                        synopsisExpanded ? null : movie.id;
                                  });
                                },
                                child: Text(
                                  synopsisExpanded ? 'Less' : 'More',
                                  style: const TextStyle(
                                    color: Md3Colors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          Text(
                            remaining <= 1
                                ? 'You can change your rating later'
                                : '$remaining choices ready. You can change your rating later.',
                            style: const TextStyle(
                              color: Md3Colors.muted,
                              fontSize: 13,
                              height: 1.38,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildRatingTray(movie),
            ),
          ],
        ),
      ),
    );
  }

  String _candidateMetadata(Movie movie) {
    final values = <String>[
      if (movie.releaseDate.year > 1) movie.releaseDate.year.toString(),
      movie.movieType == MovieType.tv ? 'TV' : 'Movie',
      if (movie.duration > 0) '${movie.duration} min',
    ];

    return values.join('  /  ');
  }

  Widget _buildRatingHeader(int profileCount) {
    final progress = (profileCount / targetRatings).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Rate Movies',
                  style: TextStyle(
                    color: Md3Colors.text,
                    fontSize: 28,
                    height: 1.21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: isCompleting ? null : _openLogin,
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                    color: Md3Colors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More onboarding options',
                icon: const Icon(Icons.more_horiz_rounded),
                constraints: const BoxConstraints(minWidth: 180),
                color: Md3Colors.surface,
                onSelected: (value) {
                  if (value == 'skip') {
                    _skipOnboarding();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'skip',
                    child: Text('Skip for now'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Text(
          'Rate 10 movies to build your taste profile.',
          style: TextStyle(
            color: Md3Colors.muted,
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$profileCount of $targetRatings movies rated',
          style: const TextStyle(
            color: Md3Colors.text,
            fontSize: 14,
            height: 1.29,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: progress,
            backgroundColor: const Color(0xffdfe5eb),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Md3Colors.primary,
            ),
          ),
        ),
      ],
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
              padding: EdgeInsets.fromLTRB(
                Md3Layout.pageHorizontalInset(context),
                24,
                Md3Layout.pageHorizontalInset(context),
                148,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Md3Card(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xffe5f3eb),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Md3Colors.success,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profileCount >= targetRatings
                              ? 'Taste profile ready'
                              : 'Your taste profile has started',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Md3Colors.text,
                            fontSize: 28,
                            height: 1.21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          deckEmpty
                              ? 'No more starter movies are available right now. You can keep building your profile from Discover.'
                              : 'We have enough ratings to generate better recommendations.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Md3Colors.muted,
                            fontSize: 16,
                            height: 1.44,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Md3Colors.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$profileCount movies rated',
                            style: const TextStyle(
                              color: Md3Colors.primary,
                              fontSize: 14,
                              height: 1.29,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomBar(
                primaryText: isCompleting
                    ? 'Saving your profile'
                    : profileCount >= targetRatings
                        ? 'Get Recommendations'
                        : 'Go to Discover',
                primaryIcon: profileCount >= targetRatings
                    ? Icons.bolt_rounded
                    : Icons.explore_rounded,
                onPrimary: isCompleting
                    ? null
                    : profileCount >= targetRatings
                        ? _openRecommendations
                        : _finishOnboarding,
                secondaryText:
                    profileCount >= targetRatings ? 'Go to Discover' : 'Back',
                onSecondary: isCompleting ? null : _finishOnboarding,
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

  Widget _buildRatingTray(Movie movie) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final useWrappedLayout = textScale >= 1.6;

    return Semantics(
      container: true,
      label: 'Rating actions for ${movie.title}',
      child: Md3LiquidGlass(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (useWrappedLayout) ...[
              Row(
                children: [
                  Expanded(
                    child: _ratingAction(
                      movie: movie,
                      label: 'Liked',
                      icon: Icons.favorite_rounded,
                      feedbackColor: const Color(0xff287a50),
                      height: 64,
                      onPressed: isSavingRating
                          ? null
                          : () => _rate(movie, MovieRate.liked),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ratingAction(
                      movie: movie,
                      label: 'Okay',
                      icon: Icons.sentiment_satisfied_alt_rounded,
                      feedbackColor: const Color(0xffa96716),
                      height: 64,
                      onPressed: isSavingRating
                          ? null
                          : () => _rate(movie, MovieRate.okay),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ratingAction(
                      movie: movie,
                      label: 'Disliked',
                      icon: Icons.thumb_down_alt_rounded,
                      feedbackColor: const Color(0xffb93a46),
                      height: 64,
                      onPressed: isSavingRating
                          ? null
                          : () => _rate(movie, MovieRate.notLiked),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _unseenAction(movie, height: 64),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _ratingAction(
                      movie: movie,
                      label: 'Liked',
                      icon: Icons.favorite_rounded,
                      feedbackColor: const Color(0xff287a50),
                      height: 52,
                      onPressed: isSavingRating
                          ? null
                          : () => _rate(movie, MovieRate.liked),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ratingAction(
                      movie: movie,
                      label: 'Okay',
                      icon: Icons.sentiment_satisfied_alt_rounded,
                      feedbackColor: const Color(0xffa96716),
                      height: 52,
                      onPressed: isSavingRating
                          ? null
                          : () => _rate(movie, MovieRate.okay),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ratingAction(
                      movie: movie,
                      label: 'Disliked',
                      icon: Icons.thumb_down_alt_rounded,
                      feedbackColor: const Color(0xffb93a46),
                      height: 52,
                      onPressed: isSavingRating
                          ? null
                          : () => _rate(movie, MovieRate.notLiked),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _unseenAction(movie, height: 44),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ratingAction({
    required Movie movie,
    required String label,
    required IconData icon,
    required Color feedbackColor,
    required double height,
    required VoidCallback? onPressed,
  }) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: '$label ${movie.title}',
      child: SizedBox(
        height: height,
        child: FilledButton(
          style: ButtonStyle(
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 4),
            ),
            backgroundColor: const WidgetStatePropertyAll(
              Color(0xf2ffffff),
            ),
            foregroundColor: const WidgetStatePropertyAll(Md3Colors.primary),
            overlayColor: WidgetStatePropertyAll(
              feedbackColor.withValues(alpha: 0.16),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Md3Colors.border),
              ),
            ),
            elevation: const WidgetStatePropertyAll(0),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.29,
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

  Widget _unseenAction(Movie movie, {required double height}) {
    return Semantics(
      button: true,
      enabled: !isSavingRating,
      label: "Haven't seen ${movie.title}",
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Md3Colors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: isSavingRating ? null : () => _skip(movie),
          icon: const Icon(Icons.skip_next_rounded, size: 19),
          label: const Text(
            "Haven't seen it",
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.29,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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

  Widget _buildBottomBar({
    required String primaryText,
    required IconData primaryIcon,
    required VoidCallback? onPrimary,
    required String secondaryText,
    required VoidCallback? onSecondary,
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
            height: 52,
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
    final localCount = moviesState.userMovies
        .where((movie) => MovieRate.isViewed(movie.movieRate))
        .length;
    final cachedCount =
        Provider.of<UserState>(context, listen: false).cachedRatedMoviesCount;

    return cachedCount != null && cachedCount > localCount
        ? cachedCount
        : localCount;
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
      _expandedSynopsisMovieId = null;
      isSavingRating = false;
    });
    _resetCandidateViewport();

    MSnackBar.showSnackBar('"${movie.title}" saved', true);
  }

  void _skip(Movie movie) {
    setState(() {
      skippedIds.add(movie.id);
      _expandedSynopsisMovieId = null;
    });
    _resetCandidateViewport();
  }

  Future<void> _finishOnboarding() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final navigator = Navigator.of(context);
    final completed = _ratedCount(moviesState) >= targetRatings;

    if (!await _persistOnboardingExit(completed: completed)) {
      return;
    }

    if (widget.onExitStarted != null) {
      widget.onFinished();
    } else if (navigator.canPop()) {
      navigator.pop();
    } else {
      widget.onFinished();
    }
    widget.onExitCompleted?.call();
  }

  Future<void> _skipOnboarding() async {
    final navigator = Navigator.of(context);
    if (!await _persistOnboardingExit(completed: false)) {
      return;
    }

    if (widget.onExitStarted != null) {
      widget.onFinished();
    } else if (navigator.canPop()) {
      navigator.pop();
    } else {
      widget.onFinished();
    }
    widget.onExitCompleted?.call();
  }

  Future<bool> _persistOnboardingExit({required bool completed}) async {
    if (isCompleting) {
      return false;
    }

    setState(() {
      isCompleting = true;
    });
    widget.onExitStarted?.call();

    final userState = Provider.of<UserState>(context, listen: false);
    try {
      if (completed) {
        await userState.setOnboardingCompleted(true);
      } else {
        await userState.setOnboardingSkipped(true);
      }
      return true;
    } catch (error) {
      debugPrint('Onboarding completion could not be persisted: $error');
      widget.onExitCompleted?.call();
      if (mounted) {
        setState(() {
          isCompleting = false;
        });
        MSnackBar.showSnackBar(
          'Could not save your onboarding progress. Try again.',
          false,
        );
      }
      return false;
    }
  }

  void _resetCandidateViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.jumpTo(0);
    });
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

  Future<void> _openRecommendations() async {
    final navigator = Navigator.of(context);
    if (!await _persistOnboardingExit(completed: true) || !mounted) {
      return;
    }

    final recommendationsPage = widget.recommendationsBuilder?.call(context) ??
        const RecommendationsPage(autoStart: true);
    final route = RouteHelper.createRoute(() => recommendationsPage);

    if (widget.onExitStarted != null) {
      navigator.push(route);
    } else {
      navigator.pushReplacement(route);
    }
    widget.onExitCompleted?.call();
  }
}
