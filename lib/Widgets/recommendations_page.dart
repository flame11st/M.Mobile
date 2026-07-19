import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Enums/recommendation_discovery_level.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Helpers/rating_helper.dart';
import 'package:mmobile/Helpers/route_helper.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/recommendation_discovery_session.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Variables/variables.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/filter_button.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:mmobile/Widgets/mark_watched_bottom_sheet.dart';
import 'package:mmobile/Widgets/movie_list_item_expanded.dart';
import 'package:mmobile/Widgets/onboarding_wizard_page.dart';
import 'package:mmobile/Widgets/recommendations_history_page.dart';
import 'package:provider/provider.dart';

class RecommendationsPage extends StatefulWidget {
  final bool autoStart;

  const RecommendationsPage({
    super.key,
    this.autoStart = false,
  });

  @override
  State<StatefulWidget> createState() {
    return RecommendationsPageState();
  }
}

class RecommendationsPageState extends State<RecommendationsPage> {
  final serviceAgent = ServiceAgent();
  final pageController = PageController(viewportFraction: 0.94);

  GlobalKey? globalKey;
  List<Movie> recommendedMovies = <Movie>[];
  bool isLoading = false;
  bool isButtonDisabled = false;
  bool hasRequestedRecommendations = false;
  String? recommendationError;
  MovieType selectedType = MovieType.movie;
  RecommendationDiscoveryLevel selectedDiscoveryLevel =
      RecommendationDiscoveryLevel.balanced;
  String? sessionId;
  int nextCursor = 0;
  bool hasMore = false;
  int currentIndex = 0;
  int _requestToken = 0;

  static const _generationTimeout = Duration(seconds: 24);

  @override
  void initState() {
    super.initState();

    if (widget.autoStart) {
      Future.microtask(() {
        if (mounted) {
          getRecommendations();
        }
      });
    }
  }

  @override
  void dispose() {
    _requestToken++;
    pageController.dispose();
    super.dispose();
  }

  void setSelectedType(MovieType type) {
    if (isLoading) {
      return;
    }

    setState(() {
      selectedType = type;
      recommendedMovies = [];
      sessionId = null;
      nextCursor = 0;
      hasMore = false;
      currentIndex = 0;
      hasRequestedRecommendations = false;
      recommendationError = null;
    });
  }

  void setDiscoveryLevel(RecommendationDiscoveryLevel level) {
    if (isLoading) {
      return;
    }

    setState(() {
      selectedDiscoveryLevel = level;
      recommendedMovies = [];
      sessionId = null;
      nextCursor = 0;
      hasMore = false;
      currentIndex = 0;
      hasRequestedRecommendations = false;
      recommendationError = null;
    });
  }

  Future<void> getRecommendations({bool reset = true}) async {
    if (isLoading) {
      return;
    }

    final requestToken = ++_requestToken;

    setState(() {
      isLoading = true;
      isButtonDisabled = true;
      if (reset) {
        recommendedMovies = [];
        sessionId = null;
        nextCursor = 0;
        hasMore = false;
        currentIndex = 0;
        hasRequestedRecommendations = false;
        recommendationError = null;
      }
    });

    final userState = Provider.of<UserState>(context, listen: false);
    if (!userState.isPremium && userState.aiRequestsCount % 3 == 0) {
      AdManager.showInterstitialAd();
    }

    List<Movie> movies = [];
    String? error;

    try {
      movies = await getSessionRecommendations(userState, reset)
          .timeout(_generationTimeout);
      if (movies.isEmpty && (sessionId == null || sessionId!.isEmpty)) {
        error =
            'We could not build your discovery deck. Please try again in a moment.';
      }
    } on TimeoutException {
      error =
          'MovieDiary is taking too long to build this deck. Your ratings are safe. Try again.';
    } catch (exception) {
      debugPrint('Recommendation discovery failed: $exception');
      error =
          'MovieDiary could not reach the recommendation service. Your ratings are safe. Try again.';
    }

    if (!mounted || requestToken != _requestToken) {
      return;
    }

    setState(() {
      if (reset) {
        recommendedMovies = movies;
      } else {
        recommendedMovies.addAll(movies);
      }
      isLoading = false;
      isButtonDisabled = false;
      hasRequestedRecommendations = true;
      recommendationError = error;
    });

    if (error != null && !reset) {
      MSnackBar.showSnackBar(error, false);
    }

    if (movies.isNotEmpty) {
      await userState.increaseAiRequestsCount();
    }
  }

  Future<List<Movie>> getSessionRecommendations(
      UserState userState, bool reset) async {
    RecommendationDiscoverySession? session;

    if (userState.userId == null || userState.userId!.isEmpty) {
      throw StateError('Recommendation request requires a user id.');
    }

    if (reset || sessionId == null) {
      session = await serviceAgent.createDiscoverySession(
        userState.userId!,
        selectedType,
        selectedDiscoveryLevel,
        10,
      );
    } else if (hasMore) {
      session = await serviceAgent.getDiscoverySessionPage(
          sessionId!, nextCursor, 10);
    }

    if (session == null) {
      return [];
    }

    if (session.sessionId == '00000000-0000-0000-0000-000000000000') {
      return [];
    }

    sessionId = session.sessionId;
    nextCursor = session.nextCursor;
    hasMore = session.hasMore;

    return session.items;
  }

  void maybeLoadNextPage(int index) {
    currentIndex = index;

    if (!hasMore || isLoading || recommendedMovies.length - index > 3) {
      return;
    }

    getRecommendations(reset: false);
  }

  void cancelRecommendationRequest() {
    _requestToken++;

    if (!mounted || !isLoading) {
      return;
    }

    setState(() {
      isLoading = false;
      isButtonDisabled = false;
      hasRequestedRecommendations = true;
      if (recommendedMovies.isEmpty) {
        recommendationError =
            'Discovery was cancelled. Start again when you are ready.';
      }
    });

    MSnackBar.showSnackBar('Discovery cancelled.', false);
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context, listen: false);
    final showBottomControls = recommendedMovies.isNotEmpty ||
        (!isLoading && !hasRequestedRecommendations);

    if (recommendedMovies.isNotEmpty) {
      RatingHelper.refreshMoviesRating(recommendedMovies, context);
    }

    if (ModalRoute.of(context)!.isCurrent &&
        (globalKey == null || globalKey != MyGlobals.activeKey)) {
      globalKey = GlobalKey();

      MyGlobals.activeKey = globalKey;
    }

    return Scaffold(
      backgroundColor: Md3Colors.background,
      appBar: PreferredSize(
        preferredSize: const Size(0, 0),
        child: Container(),
      ),
      body: Scaffold(
        backgroundColor: Md3Colors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Md3Colors.background,
          iconTheme: const IconThemeData(color: Md3Colors.text),
          title: buildHeading(context, userState),
        ),
        body: Stack(
          children: [
            if (isLoading && recommendedMovies.isNotEmpty)
              const SizedBox(
                height: 8,
                child: LinearProgressIndicator(minHeight: 8),
              ),
            Container(
              key: globalKey,
              margin: const EdgeInsets.only(top: 8),
              padding: EdgeInsets.only(bottom: showBottomControls ? 190 : 24),
              color: Md3Colors.background,
              child: isLoading && recommendedMovies.isEmpty
                  ? buildLoadingState(context)
                  : recommendedMovies.isEmpty
                      ? buildIntro(context)
                      : buildRecommendationDeck(),
            ),
            if (showBottomControls)
              Align(
                alignment: const Alignment(0.0, 1),
                child: buildControls(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildHeading(BuildContext context, UserState userState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        const Expanded(
          child: Text(
            'Recommended For You',
            style: TextStyle(
              color: Md3Colors.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (userState.user != null)
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                RouteHelper.createRoute(() => RecommendationsHistoryPage()),
              );
            },
            icon: const Icon(
              Icons.history,
              color: Md3Colors.primary,
            ),
          ),
      ],
    );
  }

  Widget buildIntro(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final ratedCount = moviesState.userMovies
        .where((movie) => MovieRate.isViewed(movie.movieRate))
        .length;
    final title = hasRequestedRecommendations
        ? recommendationError == null
            ? 'No recommendations found'
            : 'Discovery is temporarily unavailable'
        : 'Personal discovery';
    final message = hasRequestedRecommendations
        ? recommendationError ??
            'Try another title type or rate a few more movies to broaden your taste signals.'
        : 'Start a fresh recommendation deck based on your MovieDiary taste.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Md3Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Md3Colors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              if (hasRequestedRecommendations) ...[
                Md3PrimaryButton(
                  text: recommendationError == null
                      ? 'Rate More Movies'
                      : 'Try Again',
                  icon: recommendationError == null
                      ? Icons.swipe_rounded
                      : Icons.refresh_rounded,
                  tonal: recommendationError == null,
                  onPressed: recommendationError == null
                      ? () => _openRatingFlow(context)
                      : isButtonDisabled
                          ? null
                          : () => getRecommendations(),
                ),
                if (recommendationError == null) ...[
                  const SizedBox(height: 10),
                  Md3PrimaryButton(
                    text: 'Try Adventurous',
                    icon: Icons.explore_rounded,
                    onPressed: isButtonDisabled
                        ? null
                        : () {
                            setDiscoveryLevel(
                                RecommendationDiscoveryLevel.adventurous);
                            getRecommendations();
                          },
                  ),
                ],
              ] else if (ratedCount < 10)
                Text(
                  '$ratedCount/10 movies rated. You can start now, but 10 ratings makes the deck sharper.',
                  style: const TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                const Text(
                  'Choose a type and discovery style below, then start your deck.',
                  style: TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildLoadingState(BuildContext context) {
    final typeLabel = selectedType == MovieType.tv ? 'TV' : 'movie';
    final levelLabel = switch (selectedDiscoveryLevel) {
      RecommendationDiscoveryLevel.safe => 'familiar',
      RecommendationDiscoveryLevel.adventurous => 'adventurous',
      _ => 'balanced',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Md3Card(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Md3Colors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Md3Colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Building your deck',
                      style: TextStyle(
                        color: Md3Colors.text,
                        fontSize: 24,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(minHeight: 8),
              ),
              const SizedBox(height: 16),
              Text(
                'Matching your ratings with $levelLabel $typeLabel picks. This usually takes a few seconds.',
                style: const TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Md3Colors.primary,
                    side: const BorderSide(color: Md3Colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: cancelRecommendationRequest,
                  icon: const Icon(Icons.close_rounded, size: 19),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildRecommendationDeck() {
    return PageView.builder(
      controller: pageController,
      itemCount: recommendedMovies.length,
      onPageChanged: maybeLoadNextPage,
      itemBuilder: (context, index) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            _buildRecommendationCard(context, recommendedMovies[index], index),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${index + 1} of ${recommendedMovies.length}${hasMore ? '+' : ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendationCard(
      BuildContext context, Movie movie, int index) {
    final runtimeText = movie.movieType == MovieType.tv
        ? movie.seasonsCount > 0
            ? '${movie.seasonsCount} seasons'
            : ''
        : movie.duration > 0
            ? '${movie.duration} min'
            : '';
    final matchPercent = movie.recommendationMatchPercent > 0
        ? movie.recommendationMatchPercent
        : 82;
    final reason = movie.recommendationReason?.trim().isNotEmpty == true
        ? movie.recommendationReason!.trim()
        : 'A strong fit for the taste profile you have been building in MovieDiary.';

    return Md3Card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Md3MoviePoster(
                movie: movie,
                width: 122,
                height: 182,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (MovieRate.isViewed(movie.movieRate) ||
                        movie.movieRate == MovieRate.addedToWatchlist)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Md3OpinionBadge(movieRate: movie.movieRate),
                      ),
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: Md3Colors.text,
                        fontSize: 24,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Md3Chip(text: '${movie.releaseDate.year}'),
                        if (runtimeText.isNotEmpty) Md3Chip(text: runtimeText),
                        Md3Chip(
                          text: '$matchPercent% match',
                          icon: Icons.auto_awesome_rounded,
                          active: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      movie.genres.isNotEmpty
                          ? movie.genres.take(3).join(', ')
                          : 'Movie recommendation',
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.imdbVotes > 0
                          ? 'IMDb ${movie.imdbRate.toStringAsFixed(1)}  •  ${_formatVotes(movie.imdbVotes)} votes'
                          : 'IMDb score unavailable',
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Why you'll like it",
            style: TextStyle(
              color: Md3Colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _buildRecommendationPrimaryAction(context, movie),
          if (!MovieRate.isViewed(movie.movieRate)) ...[
            const SizedBox(height: 8),
            _buildSeenAlreadyAction(context, movie),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _openMovieDetails(context, movie),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(index == currentIndex
                ? 'Open details'
                : 'Open details before you swipe on'),
          ),
        ],
      ),
    );
  }

  Widget _buildSeenAlreadyAction(BuildContext context, Movie movie) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Md3Colors.primary,
          side: const BorderSide(color: Md3Colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
        ),
        onPressed: () => _markSeenAlready(context, movie),
        icon: const Icon(Icons.visibility_rounded, size: 19),
        label: const Text(
          'Seen already?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildRecommendationPrimaryAction(BuildContext context, Movie movie) {
    if (movie.movieRate == MovieRate.addedToWatchlist) {
      return const Md3PrimaryButton(
        text: 'Saved to Watchlist',
        icon: Icons.bookmark_added_rounded,
        tonal: true,
      );
    }

    if (MovieRate.isViewed(movie.movieRate)) {
      return Md3PrimaryButton(
        text: movie.movieRate == MovieRate.liked
            ? 'Saved as Liked'
            : movie.movieRate == MovieRate.okay
                ? 'Saved as Okay'
                : 'Saved as Disliked',
        icon: movie.movieRate == MovieRate.liked
            ? Icons.favorite_rounded
            : movie.movieRate == MovieRate.okay
                ? Icons.sentiment_satisfied_alt_rounded
                : Icons.block_rounded,
        tonal: true,
      );
    }

    return Md3PrimaryButton(
      text: 'Add to Watchlist',
      icon: Icons.bookmark_add_rounded,
      onPressed: () => _addToWatchlist(context, movie),
    );
  }

  Future<void> _addToWatchlist(BuildContext context, Movie movie) async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);

    await moviesState.changeMovieRate(
      movie.id,
      MovieRate.addedToWatchlist,
      userState.isIncognitoMode,
      movie,
    );

    if (!userState.isIncognitoMode && userState.userId != null) {
      await serviceAgent.rateMovie(
        movie.id,
        userState.userId!,
        MovieRate.addedToWatchlist,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {});
    MSnackBar.showSnackBar('Added to Watchlist.', true);
  }

  Future<void> _markSeenAlready(BuildContext context, Movie movie) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MarkWatchedBottomSheet(movie: movie),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _openMovieDetails(BuildContext context, Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MovieListItemExpanded(
          movie: movie,
          imageUrl: 'https://moviediarystorage.blob.core.windows.net/movies',
          shouldRequestReview: true,
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

  String _formatVotes(int votes) {
    if (votes >= 1000000) {
      return '${(votes / 1000000).toStringAsFixed(votes >= 10000000 ? 0 : 1)}M';
    }
    if (votes >= 1000) {
      return '${(votes / 1000).toStringAsFixed(votes >= 100000 ? 0 : 1)}K';
    }
    return '$votes';
  }

  Widget buildControls(BuildContext context) {
    return SizedBox(
      height: 182,
      child: Md3LiquidGlass(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                const Text(
                  'Type:',
                  style: TextStyle(
                    color: Md3Colors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    FilterIcon(
                      height: 30,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        bottomLeft: Radius.circular(25),
                      ),
                      width: MediaQuery.of(context).size.width / 2 - 60,
                      icon: FontAwesome.video,
                      text: 'Movies',
                      isActive: selectedType == MovieType.movie,
                      onPressedCallback: () => setSelectedType(MovieType.movie),
                    ),
                    FilterIcon(
                      height: 30,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                      width: MediaQuery.of(context).size.width / 2 - 60,
                      icon: Icons.tv,
                      text: 'TV Shows',
                      isActive: selectedType == MovieType.tv,
                      onPressedCallback: () => setSelectedType(MovieType.tv),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                buildLevelButton('Familiar', RecommendationDiscoveryLevel.safe),
                buildLevelButton(
                    'Balanced', RecommendationDiscoveryLevel.balanced),
                buildLevelButton(
                    'Adventurous', RecommendationDiscoveryLevel.adventurous),
              ],
            ),
            const SizedBox(height: 8),
            Md3PrimaryButton(
              text: isLoading
                  ? 'Building Deck'
                  : recommendedMovies.isEmpty
                      ? 'Start Discovery'
                      : 'Refresh Deck',
              icon:
                  isLoading ? Icons.hourglass_top_rounded : Icons.bolt_rounded,
              onPressed: isButtonDisabled ? null : () => getRecommendations(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLevelButton(String text, RecommendationDiscoveryLevel level) {
    final active = selectedDiscoveryLevel == level;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isLoading ? null : () => setDiscoveryLevel(level),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? Md3Colors.primary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? Md3Colors.primary : Md3Colors.border,
              ),
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? Colors.white : Md3Colors.text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
