import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
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
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:mmobile/Widgets/mark_watched_bottom_sheet.dart';
import 'package:mmobile/Widgets/movie_list_item_expanded.dart';
import 'package:mmobile/Widgets/onboarding_wizard_page.dart';
import 'package:mmobile/Widgets/recommendations_history_page.dart';
import 'package:mmobile/Widgets/search_page.dart';
import 'package:provider/provider.dart';

enum RecommendationFailureKind {
  timeout,
  unavailable,
  cancelled,
}

class _RecommendationRequest {
  final MovieType movieType;
  final RecommendationDiscoveryLevel discoveryLevel;
  final String? previousSessionId;
  final Set<String> excludedMovieIds;
  final bool isRefresh;

  const _RecommendationRequest({
    required this.movieType,
    required this.discoveryLevel,
    this.previousSessionId,
    this.excludedMovieIds = const {},
    this.isRefresh = false,
  });

  String get filterKey => '${movieType.index}:${discoveryLevel.index}';
}

class _DeckMemory {
  final String sessionId;
  final Set<String> movieIds;

  const _DeckMemory({required this.sessionId, required this.movieIds});
}

class RecommendationsPage extends StatefulWidget {
  final bool autoStart;
  final ServiceAgent? serviceAgent;
  final Duration generationTimeout;

  const RecommendationsPage({
    super.key,
    this.autoStart = false,
    this.serviceAgent,
    this.generationTimeout = const Duration(seconds: 24),
  });

  @override
  State<StatefulWidget> createState() {
    return RecommendationsPageState();
  }
}

class RecommendationsPageState extends State<RecommendationsPage> {
  late final ServiceAgent serviceAgent;
  final pageController = PageController();

  GlobalKey? globalKey;
  List<Movie> recommendedMovies = <Movie>[];
  bool isLoading = false;
  bool isButtonDisabled = false;
  bool hasRequestedRecommendations = false;
  String? recommendationError;
  MovieType selectedType = MovieType.movie;
  RecommendationDiscoveryLevel selectedDiscoveryLevel =
      RecommendationDiscoveryLevel.balanced;
  MovieType? deckType;
  RecommendationDiscoveryLevel? deckDiscoveryLevel;
  RecommendationFailureKind? failureKind;
  String? sessionId;
  int nextCursor = 0;
  bool hasMore = false;
  int currentIndex = 0;
  bool isPaging = false;
  int requestedCount = 10;
  int availableCount = 0;
  bool isPartialDeck = false;
  bool alternativesExhausted = false;
  bool _lastRequestWasRefresh = false;
  _RecommendationRequest? _retryRequest;
  final Map<String, _DeckMemory> _deckMemories = {};
  int _requestToken = 0;
  final Set<String> _savingMovieIds = <String>{};

  bool get isDeckStale =>
      recommendedMovies.isNotEmpty &&
      (deckType != selectedType ||
          deckDiscoveryLevel != selectedDiscoveryLevel);

  @override
  void initState() {
    super.initState();
    serviceAgent = widget.serviceAgent ?? ServiceAgent();

    if (widget.autoStart) {
      Future.microtask(() {
        if (mounted) {
          _getRecommendations();
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
    if (isLoading || selectedType == type) {
      return;
    }

    setState(() {
      selectedType = type;
      if (recommendedMovies.isEmpty) {
        hasRequestedRecommendations = false;
        recommendationError = null;
        failureKind = null;
        alternativesExhausted = false;
        _retryRequest = null;
      }
    });
  }

  void setDiscoveryLevel(RecommendationDiscoveryLevel level) {
    if (isLoading || selectedDiscoveryLevel == level) {
      return;
    }

    setState(() {
      selectedDiscoveryLevel = level;
      if (recommendedMovies.isEmpty) {
        hasRequestedRecommendations = false;
        recommendationError = null;
        failureKind = null;
        alternativesExhausted = false;
        _retryRequest = null;
      }
    });
  }

  Future<void> _getRecommendations({
    bool reset = true,
    bool refresh = false,
    _RecommendationRequest? retryRequest,
  }) async {
    if (isLoading) {
      return;
    }

    final request = retryRequest ??
        _buildRecommendationRequest(reset: reset, refresh: refresh);
    final requestToken = ++_requestToken;

    setState(() {
      isLoading = true;
      isButtonDisabled = true;
      isPaging = !reset;
      if (reset) {
        recommendedMovies = [];
        sessionId = null;
        nextCursor = 0;
        hasMore = false;
        currentIndex = 0;
        requestedCount = 10;
        availableCount = 0;
        isPartialDeck = false;
        alternativesExhausted = false;
        _lastRequestWasRefresh = request.isRefresh;
        _retryRequest = request;
        hasRequestedRecommendations = false;
        recommendationError = null;
        failureKind = null;
      }
    });

    final userState = Provider.of<UserState>(context, listen: false);
    if (!userState.isPremium && userState.aiRequestsCount % 3 == 0) {
      AdManager.showInterstitialAd();
    }

    RecommendationDiscoverySession? session;
    String? error;
    RecommendationFailureKind? requestFailure;

    try {
      session = await _getSessionRecommendations(
        userState,
        reset,
        request,
      ).timeout(widget.generationTimeout);
    } on TimeoutException {
      error =
          'MovieDiary is taking too long to build this deck. Your ratings are safe. Try again.';
      requestFailure = RecommendationFailureKind.timeout;
    } catch (exception) {
      debugPrint('Recommendation discovery failed: $exception');
      error =
          'MovieDiary could not reach the recommendation service. Your ratings are safe. Try again.';
      requestFailure = RecommendationFailureKind.unavailable;
    }

    if (!mounted || requestToken != _requestToken) {
      return;
    }

    final excludedMovieIds = request.excludedMovieIds;
    final sessionItems = session?.items ?? const <Movie>[];
    final movies = excludedMovieIds.isEmpty
        ? sessionItems
        : sessionItems
            .where((movie) => !excludedMovieIds.contains(movie.id))
            .toList(growable: false);
    final removedDuplicateItems = movies.length != sessionItems.length;
    final validSessionId = session != null &&
        session.sessionId != '00000000-0000-0000-0000-000000000000';

    setState(() {
      if (reset) {
        recommendedMovies = movies;
      } else {
        recommendedMovies.addAll(movies);
      }
      isLoading = false;
      isButtonDisabled = false;
      isPaging = false;
      hasRequestedRecommendations = true;
      recommendationError = error;
      failureKind = requestFailure;
      if (reset && error == null) {
        deckType = request.movieType;
        deckDiscoveryLevel = request.discoveryLevel;
        _retryRequest = null;
      }
      if (session != null && error == null) {
        sessionId = validSessionId ? session.sessionId : null;
        nextCursor = session.nextCursor;
        hasMore = session.hasMore;
        requestedCount = session.requestedCount;
        availableCount =
            removedDuplicateItems ? movies.length : session.availableCount;
        isPartialDeck =
            session.isPartial || (removedDuplicateItems && movies.isNotEmpty);
        alternativesExhausted = session.alternativesExhausted ||
            (sessionItems.isEmpty && !session.hasMore) ||
            (removedDuplicateItems && movies.length < requestedCount);

        if (validSessionId) {
          final previousIds = reset
              ? const <String>{}
              : _deckMemories[request.filterKey]?.movieIds ?? const <String>{};
          _deckMemories[request.filterKey] = _DeckMemory(
            sessionId: session.sessionId,
            movieIds: <String>{
              ...previousIds,
              ...movies.map((movie) => movie.id),
            },
          );
        }
      }
    });

    if (error != null && !reset) {
      MSnackBar.showSnackBar(error, false);
    }

    if (movies.isNotEmpty) {
      await userState.increaseAiRequestsCount();
    }
  }

  _RecommendationRequest _buildRecommendationRequest({
    required bool reset,
    required bool refresh,
  }) {
    if (!reset) {
      return _RecommendationRequest(
        movieType: deckType ?? selectedType,
        discoveryLevel: deckDiscoveryLevel ?? selectedDiscoveryLevel,
      );
    }

    final movieType = selectedType;
    final discoveryLevel = selectedDiscoveryLevel;
    final filterKey = '${movieType.index}:${discoveryLevel.index}';
    final rememberedDeck = _deckMemories[filterKey];
    final currentDeckMatches = recommendedMovies.isNotEmpty &&
        deckType == movieType &&
        deckDiscoveryLevel == discoveryLevel;
    final shouldRefresh =
        refresh || (!currentDeckMatches && rememberedDeck != null);

    return _RecommendationRequest(
      movieType: movieType,
      discoveryLevel: discoveryLevel,
      previousSessionId: shouldRefresh
          ? currentDeckMatches
              ? sessionId
              : rememberedDeck?.sessionId
          : null,
      excludedMovieIds: shouldRefresh
          ? currentDeckMatches
              ? recommendedMovies.map((movie) => movie.id).toSet()
              : rememberedDeck?.movieIds ?? const {}
          : const {},
      isRefresh: shouldRefresh,
    );
  }

  Future<RecommendationDiscoverySession> _getSessionRecommendations(
    UserState userState,
    bool reset,
    _RecommendationRequest request,
  ) async {
    RecommendationDiscoverySession? session;

    if (userState.userId == null || userState.userId!.isEmpty) {
      throw StateError('Recommendation request requires a user id.');
    }

    if (reset || sessionId == null) {
      session = await serviceAgent.createDiscoverySession(
        userState.userId!,
        request.movieType,
        request.discoveryLevel,
        10,
        previousSessionId: request.previousSessionId,
        excludedMovieIds: request.excludedMovieIds,
      );
    } else if (hasMore) {
      session = await serviceAgent.getDiscoverySessionPage(
          sessionId!, nextCursor, 10);
    }

    if (session == null) {
      throw const HttpException('Recommendation service returned no session.');
    }

    return session;
  }

  void maybeLoadNextPage(int index) {
    currentIndex = index;

    if (!hasMore || isLoading || recommendedMovies.length - index > 3) {
      return;
    }

    _getRecommendations(reset: false);
  }

  void cancelRecommendationRequest() {
    _requestToken++;

    if (!mounted || !isLoading) {
      return;
    }

    setState(() {
      isLoading = false;
      isButtonDisabled = false;
      isPaging = false;
      hasRequestedRecommendations = true;
      if (recommendedMovies.isEmpty) {
        recommendationError =
            'Discovery was cancelled. Start again when you are ready.';
        failureKind = RecommendationFailureKind.cancelled;
      }
    });

    MSnackBar.showSnackBar('Discovery cancelled.', false);
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context, listen: false);
    final isFullPageLoading = isLoading && !isPaging;
    final showStickyCommand = !isFullPageLoading;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final stickyBottom = safeBottom > 8 ? safeBottom : 8.0;
    final contentBottomPadding =
        showStickyCommand ? 68 + stickyBottom + 16 : 24.0;

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
      body: Column(
        children: [
          buildHeading(context, userState),
          buildFilterBar(context),
          if (isDeckStale) buildStaleDeckNotice(),
          Expanded(
            child: Stack(
              children: [
                Container(
                  key: globalKey,
                  color: Md3Colors.background,
                  child: isFullPageLoading
                      ? buildLoadingState(context)
                      : recommendedMovies.isEmpty
                          ? buildIntro(context, contentBottomPadding)
                          : buildRecommendationDeck(contentBottomPadding),
                ),
                if (isPaging)
                  const Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      color: Md3Colors.primary,
                      backgroundColor: Md3Colors.primarySoft,
                    ),
                  ),
                if (showStickyCommand)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: buildStickyCommand(context, stickyBottom),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeading(BuildContext context, UserState userState) {
    final canOpenHistory =
        userState.userId != null && userState.userId!.isNotEmpty;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Md3Colors.text,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (canOpenHistory)
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        tooltip: 'Recommendation history',
                        onPressed: () {
                          Navigator.of(context).push(
                            RouteHelper.createRoute(
                              () => const RecommendationsHistoryPage(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.history_rounded,
                          color: Md3Colors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(6, 4, 6, 12),
              child: Text(
                'Recommended For You',
                style: TextStyle(
                  color: Md3Colors.text,
                  fontSize: 32,
                  height: 38 / 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFilterBar(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return Semantics(
      container: true,
      label: 'Recommendation filters',
      child: SizedBox(
        key: const Key('recommendation-filter-bar'),
        height: 52,
        child: Md3LiquidGlass(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(4),
          borderRadius: BorderRadius.circular(24),
          blur: 20,
          tint: const Color(0xccffffff),
          borderColor: const Color(0xffe9edf2),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 290;

              return Row(
                children: [
                  Expanded(
                    flex: largeText
                        ? 6
                        : constraints.maxWidth < 290
                            ? 5
                            : 4,
                    child: _buildTypeSegment(
                      compact: compact || largeText,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: largeText ? 4 : 3,
                    child: _buildDiscoveryStyleMenu(
                      compact: compact,
                      labelOnly: largeText,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSegment({required bool compact}) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Md3Colors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeOption(
              type: MovieType.movie,
              label: 'Movies',
              icon: Icons.movie_outlined,
              compact: compact,
            ),
          ),
          Expanded(
            child: _buildTypeOption(
              type: MovieType.tv,
              label: 'TV',
              icon: Icons.tv_rounded,
              compact: compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required MovieType type,
    required String label,
    required IconData icon,
    required bool compact,
  }) {
    final selected = selectedType == type;

    return Semantics(
      button: true,
      selected: selected,
      label: label == 'TV' ? 'TV shows' : label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () => setSelectedType(type),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Md3Colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!compact) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? Colors.white : Md3Colors.text,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      color: selected ? Colors.white : Md3Colors.text,
                      fontSize: 14,
                      height: 18 / 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryStyleMenu({
    required bool compact,
    bool labelOnly = false,
  }) {
    final label = _discoveryLevelLabel(selectedDiscoveryLevel);

    return Semantics(
      button: true,
      value: label,
      label: 'Discovery style',
      child: PopupMenuButton<RecommendationDiscoveryLevel>(
        enabled: !isLoading,
        tooltip: 'Discovery style: $label',
        onSelected: setDiscoveryLevel,
        itemBuilder: (context) => RecommendationDiscoveryLevel.values
            .map(
              (level) => PopupMenuItem<RecommendationDiscoveryLevel>(
                value: level,
                height: 48,
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: level == selectedDiscoveryLevel
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Md3Colors.primary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(_discoveryLevelLabel(level)),
                  ],
                ),
              ),
            )
            .toList(),
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(
            horizontal: labelOnly
                ? 6
                : compact
                    ? 8
                    : 12,
          ),
          decoration: BoxDecoration(
            color: Md3Colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Md3Colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!labelOnly)
                const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: Md3Colors.primary,
                ),
              if (labelOnly || !compact) ...[
                if (!labelOnly) const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Md3Colors.text,
                      fontSize: 14,
                      height: 18 / 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              if (!labelOnly) ...[
                const SizedBox(width: 2),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: Md3Colors.muted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStaleDeckNotice() {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Md3Layout.pageHorizontalInset(context),
          8,
          Md3Layout.pageHorizontalInset(context),
          0,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Md3Colors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Filters changed. Your current deck stays until you build a ${_typeDeckLabel(selectedType)} deck.',
                style: const TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIntro(BuildContext context, double bottomPadding) {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final ratedCount = moviesState.userMovies
        .where((movie) => MovieRate.isViewed(movie.movieRate))
        .length;
    final activeType = deckType ?? selectedType;
    final activeLevel = deckDiscoveryLevel ?? selectedDiscoveryLevel;
    final selection =
        '${_discoveryLevelLabel(activeLevel)} ${_typeDeckLabel(activeType)}';
    final isExhausted = hasRequestedRecommendations &&
        recommendationError == null &&
        alternativesExhausted;
    final title = !hasRequestedRecommendations
        ? 'Personal discovery'
        : switch (failureKind) {
            RecommendationFailureKind.timeout => 'This deck took too long',
            RecommendationFailureKind.unavailable =>
              'Recommendations unavailable',
            RecommendationFailureKind.cancelled => 'Discovery paused',
            null => _lastRequestWasRefresh
                ? 'No new recommendations available'
                : 'No recommendations available',
          };
    final message = !hasRequestedRecommendations
        ? 'Start a fresh recommendation deck based on your MovieDiary taste.'
        : recommendationError ??
            (isExhausted
                ? 'You have seen every $selection pick available right now. Your selection stayed ${_discoveryLevelLabel(activeLevel)}.'
                : 'Rate a few more movies or choose another discovery style, then try again.');
    final showBackAction = failureKind != null;
    final showEmptyActions =
        hasRequestedRecommendations && recommendationError == null;

    return ListView(
      key: const Key('recommendation-terminal-state'),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
      children: [
        Md3Card(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Md3Colors.text,
                  fontSize: 24,
                  height: 29 / 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 16,
                  height: 23 / 16,
                ),
              ),
              const SizedBox(height: 16),
              if (!hasRequestedRecommendations && ratedCount < 10)
                Text(
                  '$ratedCount/10 movies rated. You can start now, but 10 ratings makes the deck sharper.',
                  style: const TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else if (!hasRequestedRecommendations)
                const Text(
                  'Choose a type and discovery style above, then start your deck.',
                  style: TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (showEmptyActions) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SearchStandalonePage(),
                        ),
                      ),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Search titles'),
                    ),
                    if (selectedDiscoveryLevel !=
                        RecommendationDiscoveryLevel.adventurous)
                      TextButton.icon(
                        onPressed: () {
                          setDiscoveryLevel(
                            RecommendationDiscoveryLevel.adventurous,
                          );
                          _getRecommendations();
                        },
                        icon: const Icon(Icons.explore_rounded, size: 18),
                        label: const Text('Try Adventurous'),
                      ),
                  ],
                ),
              ],
              if (showBackAction)
                SizedBox(
                  height: 44,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back to Discover'),
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
      key: const Key('recommendation-loading-state'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Semantics(
          liveRegion: true,
          label:
              'Building a $levelLabel $typeLabel recommendation deck. You can cancel.',
          child: Md3Card(
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
                          height: 29 / 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    minHeight: 8,
                    color: Md3Colors.primary,
                    backgroundColor: Md3Colors.primarySoft,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Matching your ratings with $levelLabel $typeLabel picks. This usually takes a few seconds.',
                  style: const TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 16,
                    height: 23 / 16,
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
        ),
      ],
    );
  }

  Widget buildRecommendationDeck(double bottomPadding) {
    return PageView.builder(
      key: const Key('recommendation-result-deck'),
      controller: pageController,
      itemCount: recommendedMovies.length,
      onPageChanged: maybeLoadNextPage,
      itemBuilder: (context, index) {
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
          children: [
            if (isPartialDeck) _buildPartialDeckNotice(),
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

  Widget _buildPartialDeckNotice() {
    final activeType = deckType ?? selectedType;
    final activeLevel = deckDiscoveryLevel ?? selectedDiscoveryLevel;

    return Semantics(
      liveRegion: true,
      label:
          '$availableCount recommendations available for the ${_discoveryLevelLabel(activeLevel)} ${_typeDeckLabel(activeType)} selection.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Md3Colors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$availableCount recommendations available for this ${_discoveryLevelLabel(activeLevel).toLowerCase()} ${_typeDeckLabel(activeType)} selection.',
                style: const TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
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
    final reason = movie.recommendationReason?.trim().isNotEmpty == true
        ? movie.recommendationReason!.trim()
        : 'A strong fit for the taste profile you have been building in MovieDiary.';

    final isSaving = _savingMovieIds.contains(movie.id);

    return Md3Card(
      key: Key('recommendation-card-$index'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Md3MoviePoster(
                movie: movie,
                width: 104,
                height: 156,
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
                        height: 29 / 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (movie.recommendationMatchPercent > 0)
                      MediaQuery.textScalerOf(context).scale(1) > 1.3
                          ? Text(
                              '${movie.recommendationMatchPercent}% match',
                              style: const TextStyle(
                                color: Md3Colors.primary,
                                fontSize: 13,
                                height: 18 / 13,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : Md3Chip(
                              text:
                                  '${movie.recommendationMatchPercent}% match',
                              icon: Icons.auto_awesome_rounded,
                              active: true,
                            ),
                    const SizedBox(height: 12),
                    Text(
                      [
                        '${movie.releaseDate.year}',
                        if (runtimeText.isNotEmpty) runtimeText,
                      ].join('  •  '),
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      movie.genres.isNotEmpty
                          ? movie.genres.take(3).join(', ')
                          : movie.movieType == MovieType.tv
                              ? 'TV recommendation'
                              : 'Movie recommendation',
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
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
              fontSize: 20,
              height: 25 / 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 16,
              height: 23 / 16,
            ),
          ),
          const SizedBox(height: 20),
          _buildRecommendationPrimaryAction(context, movie, isSaving),
          if (!MovieRate.isViewed(movie.movieRate)) ...[
            const SizedBox(height: 8),
            _buildSeenAlreadyAction(context, movie, isSaving),
          ],
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Md3Colors.primary,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed:
                  isSaving ? null : () => _openMovieDetails(context, movie),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text(
                'Open details',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeenAlreadyAction(
    BuildContext context,
    Movie movie,
    bool isSaving,
  ) {
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
        onPressed: isSaving ? null : () => _markSeenAlready(context, movie),
        icon: const Icon(Icons.visibility_rounded, size: 19),
        label: const Text(
          'Seen already',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildRecommendationPrimaryAction(
    BuildContext context,
    Movie movie,
    bool isSaving,
  ) {
    if (movie.movieRate == MovieRate.addedToWatchlist) {
      return const Md3PrimaryButton(
        text: 'In Watchlist',
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
      text: isSaving ? 'Saving' : 'Add to Watchlist',
      icon: Icons.bookmark_add_rounded,
      onPressed: isSaving ? null : () => _addToWatchlist(context, movie),
    );
  }

  Future<void> _addToWatchlist(BuildContext context, Movie movie) async {
    if (_savingMovieIds.contains(movie.id)) {
      return;
    }

    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final previousRate = movie.movieRate;

    setState(() => _savingMovieIds.add(movie.id));

    try {
      await moviesState.changeMovieRate(
        movie.id,
        MovieRate.addedToWatchlist,
        userState.isIncognitoMode,
        movie,
      );

      if (!userState.isIncognitoMode) {
        final userId = userState.userId;
        if (userId == null || userId.isEmpty || ServiceAgent.state == null) {
          throw const HttpException('Signed-in movie update is unavailable.');
        }

        final response = await serviceAgent.rateMovie(
          movie.id,
          userId,
          MovieRate.addedToWatchlist,
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException(
            'Movie update failed with ${response.statusCode}.',
          );
        }
      }
    } catch (_) {
      await moviesState.changeMovieRate(
        movie.id,
        previousRate,
        userState.isIncognitoMode,
        movie,
      );
      if (!mounted) {
        return;
      }

      setState(() => _savingMovieIds.remove(movie.id));
      MSnackBar.showWithMessenger(
        messenger,
        'Couldn’t update ${movie.title}. Try again.',
        false,
        duration: const Duration(milliseconds: 2500),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _savingMovieIds.remove(movie.id));
    MSnackBar.showWithMessenger(
      messenger,
      'Added to Watchlist.',
      true,
      duration: const Duration(milliseconds: 2500),
    );
  }

  Future<void> _markSeenAlready(BuildContext context, Movie movie) async {
    await showMarkWatchedBottomSheet(
      context: context,
      movie: movie,
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
          mode: RatingFlowMode.continuous,
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

  Widget buildStickyCommand(BuildContext context, double bottomInset) {
    final label = _primaryCommandLabel();
    final icon = switch (label) {
      'Refresh deck' || 'Retry' => Icons.refresh_rounded,
      'Try Adventurous' => Icons.explore_rounded,
      'Rate more' => Icons.swipe_rounded,
      _ => Icons.bolt_rounded,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        key: const Key('recommendation-sticky-command-bar'),
        height: 68,
        child: Md3LiquidGlass(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(24),
          blur: 20,
          tint: const Color(0xccffffff),
          borderColor: const Color(0xffe9edf2),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('recommendation-primary-command'),
              style: FilledButton.styleFrom(
                backgroundColor: Md3Colors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Md3Colors.primarySoft,
                disabledForegroundColor: Md3Colors.muted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: isButtonDisabled ? null : _runPrimaryCommand,
              icon: Icon(icon, size: 20),
              label: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _primaryCommandLabel() {
    if (isDeckStale) {
      return 'Build ${_typeDeckLabel(selectedType)} deck';
    }

    if (recommendedMovies.isNotEmpty) {
      return alternativesExhausted ? 'Rate more' : 'Refresh deck';
    }

    if (!hasRequestedRecommendations) {
      return 'Start Discovery';
    }

    if (failureKind == RecommendationFailureKind.timeout ||
        failureKind == RecommendationFailureKind.unavailable) {
      return 'Retry';
    }

    if (failureKind == RecommendationFailureKind.cancelled) {
      return 'Start Discovery';
    }

    return 'Rate more';
  }

  void _runPrimaryCommand() {
    final label = _primaryCommandLabel();

    if (label == 'Rate more') {
      _openRatingFlow(context);
      return;
    }

    final retryRequest =
        label == 'Retry' || failureKind == RecommendationFailureKind.cancelled
            ? _retryRequest
            : null;
    _getRecommendations(
      refresh: label == 'Refresh deck',
      retryRequest: retryRequest,
    );
  }

  String _typeDeckLabel(MovieType type) {
    return type == MovieType.tv ? 'TV' : 'movie';
  }

  String _discoveryLevelLabel(RecommendationDiscoveryLevel level) {
    return switch (level) {
      RecommendationDiscoveryLevel.safe => 'Familiar',
      RecommendationDiscoveryLevel.adventurous => 'Adventurous',
      RecommendationDiscoveryLevel.balanced => 'Balanced',
    };
  }
}
