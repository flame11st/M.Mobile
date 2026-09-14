import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Enums/recommendation_discovery_level.dart';
import 'package:mmobile/Helpers/rating_helper.dart';
import 'package:mmobile/Helpers/route_helper.dart';
import 'package:mmobile/Helpers/ad_policy.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/recommendation_discovery_session.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Services/product_analytics.dart';
import 'package:mmobile/Services/monetization_service.dart';
import 'package:mmobile/Services/rewarded_allowance_flow.dart';
import 'package:mmobile/Variables/variables.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:mmobile/Widgets/mark_watched_bottom_sheet.dart';
import 'package:mmobile/Widgets/movie_list_item_expanded.dart';
import 'package:mmobile/Widgets/onboarding_wizard_page.dart';
import 'package:mmobile/Widgets/premium.dart';
import 'package:mmobile/Widgets/rewarded_allowance_sheet.dart';
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
  final RewardedAllowanceFlowController? rewardedAllowanceFlow;
  final WidgetBuilder? premiumPageBuilder;
  final Duration generationTimeout;
  final Duration generationTimeoutGrace;

  const RecommendationsPage({
    super.key,
    this.autoStart = false,
    this.serviceAgent,
    this.rewardedAllowanceFlow,
    this.premiumPageBuilder,
    this.generationTimeout = const Duration(seconds: 24),
    this.generationTimeoutGrace = const Duration(seconds: 16),
  });

  @override
  State<StatefulWidget> createState() {
    return RecommendationsPageState();
  }
}

class RecommendationsPageState extends State<RecommendationsPage> {
  static const _mutationTimeout = Duration(seconds: 12);
  static const _deckMotionDuration = Duration(milliseconds: 200);

  late final ServiceAgent serviceAgent;
  late final RewardedAllowanceFlowController rewardedAllowanceFlow;
  late final bool _ownsRewardedAllowanceFlow;
  final pageController = PageController();
  final Md3PosterPrefetchController _posterPrefetchController =
      Md3PosterPrefetchController();

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
  RecommendationDeckOrigin deckOrigin = RecommendationDeckOrigin.unknown;
  DateTime? deckGeneratedAt;
  RecommendationAllowance? recommendationAllowance;
  bool _lastRequestWasRefresh = false;
  _RecommendationRequest? _retryRequest;
  final Map<String, _DeckMemory> _deckMemories = {};
  int _requestToken = 0;
  int _deckRevision = 0;
  final Set<String> _savingMovieIds = <String>{};
  final Set<String> _expandedReasonMovieIds = <String>{};
  String? _scheduledPosterPrefetchKey;
  bool _deckCompleted = false;
  bool _completionInFlight = false;
  int? _rewardOfferRequestToken;

  bool get isDeckStale =>
      recommendedMovies.isNotEmpty &&
      (deckType != selectedType ||
          deckDiscoveryLevel != selectedDiscoveryLevel);

  @override
  void initState() {
    super.initState();
    serviceAgent = widget.serviceAgent ?? ServiceAgent();
    _ownsRewardedAllowanceFlow = widget.rewardedAllowanceFlow == null;
    rewardedAllowanceFlow =
        widget.rewardedAllowanceFlow ?? RewardedAllowanceFlowController();
    rewardedAllowanceFlow.addListener(_syncRewardedAllowance);

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
    _deckRevision++;
    _posterPrefetchController.dispose();
    pageController.dispose();
    rewardedAllowanceFlow.removeListener(_syncRewardedAllowance);
    if (_ownsRewardedAllowanceFlow) {
      rewardedAllowanceFlow.dispose();
    }
    super.dispose();
  }


  void _syncRewardedAllowance() {
    final allowance = rewardedAllowanceFlow.allowance;
    if (!mounted ||
        rewardedAllowanceFlow.state != RewardedAllowanceFlowState.completed ||
        allowance == null ||
        identical(recommendationAllowance, allowance)) {
      return;
    }
    // Persisted credits belong to the page, not to the sheet's build action.
    // This also handles confirmation arriving after the sheet is dismissed.
    setState(() {
      recommendationAllowance = allowance;
    });
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
        deckOrigin = RecommendationDeckOrigin.unknown;
        deckGeneratedAt = null;
        recommendationAllowance = null;
        _deckCompleted = false;
        _completionInFlight = false;
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
        deckOrigin = RecommendationDeckOrigin.unknown;
        deckGeneratedAt = null;
        recommendationAllowance = null;
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
    if (reset) {
      _deckRevision++;
      _scheduledPosterPrefetchKey = null;
      _posterPrefetchController.cancel();
    }

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
        deckOrigin = RecommendationDeckOrigin.unknown;
        deckGeneratedAt = null;
        recommendationAllowance = null;
        _lastRequestWasRefresh = request.isRefresh;
        _retryRequest = request;
        hasRequestedRecommendations = false;
        recommendationError = null;
        failureKind = null;
      }
    });
    _scheduleNextRecommendationPoster();

    final userState = Provider.of<UserState>(context, listen: false);
    if (reset) {
      unawaited(ProductAnalytics.instance.track(
        ProductAnalyticsEventName.recommendationStarted,
        parameters: {
          ProductAnalyticsParameter.mediaType:
              request.movieType == MovieType.tv ? 'tv' : 'movie',
          ProductAnalyticsParameter.discoveryMode:
              _discoveryLevelLabel(request.discoveryLevel).toLowerCase(),
          ProductAnalyticsParameter.entryPoint: retryRequest != null
              ? 'retry'
              : request.isRefresh
                  ? 'refresh'
                  : 'start',
          ProductAnalyticsParameter.sourceSurface: 'recommendations',
        },
      ));
    }
    RecommendationDiscoverySession? session;
    String? error;
    RecommendationFailureKind? requestFailure;

    try {
      final requestFuture = _getSessionRecommendations(
        userState,
        reset,
        request,
      );
      try {
        session = await requestFuture.timeout(widget.generationTimeout);
      } on TimeoutException {
        // The API can commit the allowance reservation and recommendation
        // batch just after the primary UI deadline. Keep observing the same
        // request for a short bounded grace period so a completed rewarded
        // deck is not hidden behind a false timeout or retried as new work.
        session = await requestFuture.timeout(widget.generationTimeoutGrace);
      }
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

    if (session != null && error == null) {
      unawaited(trackRewardedCreditTransitions(session.allowance));
      unawaited(trackRecommendationAllowanceConfiguration(session.allowance));
    }

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
      if (reset &&
          error == null &&
          !(session?.allowance?.requestInProgress ?? false) &&
          (movies.isNotEmpty || !(session?.allowance?.limitReached ?? false))) {
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
        recommendationAllowance = session.allowance;
        if (reset) {
          deckOrigin = session.origin;
          deckGeneratedAt = session.generatedAt;
        }
        isPartialDeck =
            session.isPartial || (removedDuplicateItems && movies.isNotEmpty);
        alternativesExhausted = session.alternativesExhausted ||
            (sessionItems.isEmpty &&
                !session.hasMore &&
                !(session.allowance?.limitReached ?? false)) ||
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
    _scheduleNextRecommendationPoster();

    if (error != null && !reset) {
      MSnackBar.showSnackBar(error, false);
    }

    if (movies.isNotEmpty) {
      final isSavedDeck = session?.origin == RecommendationDeckOrigin.saved;
      if (!isSavedDeck) {
        await userState.increaseAiRequestsCount();
      }
      if (reset) {
        final generatedSessionId = validSessionId ? session.sessionId : null;
        final analyticsParameters = <ProductAnalyticsParameter, Object?>{
          ProductAnalyticsParameter.mediaType:
              request.movieType == MovieType.tv ? 'tv' : 'movie',
          ProductAnalyticsParameter.discoveryMode:
              _discoveryLevelLabel(request.discoveryLevel).toLowerCase(),
          ProductAnalyticsParameter.resultCount: movies.length,
          ProductAnalyticsParameter.sourceSurface: 'recommendations',
          if (validSessionId)
            ProductAnalyticsParameter.recommendationSessionId:
                session.sessionId,
        };
        if (!isSavedDeck) {
          unawaited(ProductAnalytics.instance.track(
            ProductAnalyticsEventName.recommendationGenerated,
            parameters: analyticsParameters,
            transitionId: generatedSessionId,
          ));
        }
        if (!isSavedDeck &&
            movies.length == 10 &&
            requestedCount == 10 &&
            !hasMore) {
          unawaited(userState.monetization
              .prepareRecommendationCompletionInterstitial());
        }
        unawaited(ProductAnalytics.instance.track(
          ProductAnalyticsEventName.recommendationViewed,
          parameters: analyticsParameters,
          transitionId: generatedSessionId,
        ));
      }
    }

    if (reset && movies.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && pageController.hasClients) {
          pageController.jumpToPage(0);
        }
      });
    }

    if (reset &&
        error == null &&
        movies.isEmpty &&
        session?.allowance?.limitReached == true &&
        requestToken == _requestToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_presentRewardedAllowanceOffer(requestToken));
        }
      });
    }
  }

  Future<void> _presentRewardedAllowanceOffer(int requestToken) async {
    if (!mounted || _rewardOfferRequestToken == requestToken) {
      return;
    }
    final allowance = recommendationAllowance;
    final userState = Provider.of<UserState>(context, listen: false);
    final userId = userState.userId?.trim() ?? '';
    final decision = userState.monetization.evaluate(
      MonetizationPlacement.extraRecommendationRewarded,
      surface: MonetizationSurface.recommendationAllowance,
    );
    if (allowance == null ||
        !allowance.limitReached ||
        allowance.isPremium ||
        allowance.rewardedCreditsAvailable > 0 ||
        allowance.rewardedDecksGranted >= allowance.rewardedDecksPerDay ||
        userId.isEmpty ||
        !decision.isEligible) {
      return;
    }

    _rewardOfferRequestToken = requestToken;
    unawaited(ProductAnalytics.instance.track(
      ProductAnalyticsEventName.rewardedOfferShown,
      parameters: const {
        ProductAnalyticsParameter.placement: 'extra_recommendation_rewarded',
        ProductAnalyticsParameter.isPremium: false,
        ProductAnalyticsParameter.sourceSurface: 'recommendation_allowance',
      },
      transitionId: 'rewarded-offer-$requestToken',
    ));
    RewardedAllowanceAction? action;
    try {
      await rewardedAllowanceFlow.prepare();
      if (!mounted) {
        return;
      }

      action = await showRewardedAllowanceSheet(
        context: context,
        controller: rewardedAllowanceFlow,
        userId: userId,
        freeDecksPerDay: allowance.freeDecksPerDay,
        onPlaybackStarted: () => userState.monetization
            .recordMonetizationInteraction(MonetizationInteraction.rewardedAd),
        entitlementListenable: userState,
        isPremium: () => userState.isPremium,
      );
    } finally {
      if (_rewardOfferRequestToken == requestToken) {
        _rewardOfferRequestToken = null;
      }
    }
    if (!mounted) {
      return;
    }

    if (action == RewardedAllowanceAction.generate) {
      final durableAllowance = rewardedAllowanceFlow.allowance;
      if (durableAllowance == null ||
          durableAllowance.rewardedCreditsAvailable <= 0) {
        MSnackBar.showSnackBar(
          'Your extra deck could not be confirmed. Try again later.',
          false,
        );
        return;
      }
      setState(() {
        recommendationAllowance = durableAllowance;
      });
      // A limited response may still contain the most recently cached deck.
      // Replaying the original request would return that cache again without
      // reserving the newly earned credit. Refresh when a deck is already on
      // screen so the backend receives the previous session/exclusions and
      // generates a genuinely new rewarded deck.
      if (recommendedMovies.isNotEmpty) {
        await _getRecommendations(refresh: true);
      } else {
        await _getRecommendations(retryRequest: _retryRequest);
      }
      return;
    }

    if (action == RewardedAllowanceAction.premium ||
        action == RewardedAllowanceAction.premiumActivated) {
      if (action == RewardedAllowanceAction.premium) {
        await Navigator.of(context).push(
          RouteHelper.createRoute(
            () => widget.premiumPageBuilder?.call(context) ?? const Premium(),
          ),
        );
      }
      if (!mounted) {
        return;
      }
      final currentUserState = Provider.of<UserState>(context, listen: false);
      if (currentUserState.isPremium) {
        final intendedRequest = _retryRequest;
        setState(() {
          recommendationAllowance = null;
          hasRequestedRecommendations = false;
          recommendationError = null;
          alternativesExhausted = false;
          failureKind = null;
        });
        MSnackBar.showSnackBar(
          'Premium is active. Fresh recommendation decks are unlocked.',
          true,
        );
        await _getRecommendations(retryRequest: intendedRequest);
      }
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
    _scheduleNextRecommendationPoster();

    if (!hasMore || isLoading || recommendedMovies.length - index > 3) {
      return;
    }

    _getRecommendations(reset: false);
  }

  void _scheduleNextRecommendationPoster() {
    final movies = List<Movie>.unmodifiable(recommendedMovies);
    final index = currentIndex;
    final revision = _deckRevision;
    final prefetchKey =
        'recommendations:$revision:${sessionId ?? 'pending'}:$index:${movies.length}';
    if (_scheduledPosterPrefetchKey == prefetchKey) {
      return;
    }
    _scheduledPosterPrefetchKey = prefetchKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          revision != _deckRevision ||
          _scheduledPosterPrefetchKey != prefetchKey) {
        return;
      }
      _posterPrefetchController.prefetchNext(
        context,
        movies: movies,
        currentIndex: index,
        deckKey: prefetchKey,
        logicalWidth: 152,
        logicalHeight: 228,
      );
    });
  }

  Future<void> _moveToIndex(int targetIndex) async {
    if (!mounted || !pageController.hasClients) {
      return;
    }

    final boundedIndex =
        targetIndex.clamp(0, recommendedMovies.length - 1).toInt();
    if (MediaQuery.disableAnimationsOf(context)) {
      pageController.jumpToPage(boundedIndex);
      return;
    }

    await pageController.animateToPage(
      boundedIndex,
      duration: _deckMotionDuration,
      curve: Curves.easeOut,
    );
  }

  Future<void> _moveToNext(int index) async {
    if (isLoading || _savingMovieIds.isNotEmpty) {
      return;
    }

    if (index < recommendedMovies.length - 1) {
      await _moveToIndex(index + 1);
      return;
    }

    if (!hasMore) {
      if (_isFullDeckCompletionBoundary(index)) {
        await _completeDeck(index);
      }
      return;
    }

    final previousLength = recommendedMovies.length;
    await _getRecommendations(reset: false);
    if (!mounted ||
        currentIndex != index ||
        recommendedMovies.length <= previousLength) {
      return;
    }

    await _moveToIndex(index + 1);
  }

  bool _isFullDeckCompletionBoundary(int index) {
    return index == recommendedMovies.length - 1 &&
        recommendedMovies.length == 10 &&
        requestedCount == 10 &&
        !hasMore &&
        !_deckCompleted;
  }

  Future<void> _completeDeck(int index) async {
    if (_completionInFlight || !_isFullDeckCompletionBoundary(index)) {
      return;
    }
    _completionInFlight = true;
    setState(() => _deckCompleted = true);

    // Render the normal product completion state before evaluating the optional
    // completion-boundary interstitial. Inventory is never loaded or awaited
    // here, so the flow continues immediately when no ad is ready.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }

    final completionId = '${sessionId ?? 'local-deck-$_deckRevision'}:complete';
    final userState = Provider.of<UserState>(context, listen: false);
    unawaited(ProductAnalytics.instance.track(
      ProductAnalyticsEventName.recommendationDeckCompleted,
      parameters: {
        ProductAnalyticsParameter.resultCount: recommendedMovies.length,
        ProductAnalyticsParameter.position: index + 1,
        ProductAnalyticsParameter.sourceSurface: 'recommendations',
        if (sessionId != null)
          ProductAnalyticsParameter.recommendationSessionId: sessionId,
      },
      transitionId: completionId,
    ));
    await userState.monetization.recordRecommendationDeckCompleted(
      completionId: completionId,
      recommendationSessionId: sessionId,
      recommendationMode:
          _discoveryLevelLabel(deckDiscoveryLevel ?? selectedDiscoveryLevel)
              .toLowerCase(),
      mediaType: (deckType ?? selectedType) == MovieType.tv ? 'tv' : 'movie',
    );
  }

  Future<void> _advanceAfterAction(Movie movie) async {
    if (!mounted ||
        currentIndex >= recommendedMovies.length ||
        recommendedMovies[currentIndex].id != movie.id) {
      return;
    }

    final index = currentIndex;
    if (index < recommendedMovies.length - 1) {
      await _moveToIndex(index + 1);
      return;
    }

    if (hasMore) {
      final previousLength = recommendedMovies.length;
      await _getRecommendations(reset: false);
      if (mounted &&
          currentIndex == index &&
          recommendedMovies.length > previousLength) {
        await _moveToIndex(index + 1);
      }
    }
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
    final showStickyCommand = !_deckCompleted &&
        !isFullPageLoading &&
        (recommendedMovies.isEmpty || alternativesExhausted);
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
                          : _deckCompleted
                              ? buildDeckCompletion(contentBottomPadding)
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
    final showTopGenerationAction = recommendedMovies.isNotEmpty &&
        !_deckCompleted &&
        (!alternativesExhausted || isDeckStale);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: Md3Spacing.x8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Md3Spacing.x12),
              child: SizedBox(
                height: Md3Targets.minimum,
                child: Row(
                  children: [
                    SizedBox(
                      width: Md3Targets.minimum,
                      height: Md3Targets.minimum,
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
                    if (showTopGenerationAction) ...[
                      Flexible(child: _buildTopGenerationAction(userState)),
                      if (canOpenHistory) const SizedBox(width: Md3Spacing.x8),
                    ],
                    if (canOpenHistory)
                      SizedBox(
                        width: Md3Targets.minimum,
                        height: Md3Targets.minimum,
                        child: IconButton(
                          key: const Key('recommendation-history-action'),
                          tooltip: 'Recommendation history',
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(context).push(
                                    RouteHelper.createRoute(
                                      () => const RecommendationsHistoryPage(),
                                    ),
                                  ),
                          icon: const Icon(
                            Icons.history_rounded,
                            color: Md3Colors.text,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Md3Spacing.x12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Md3Spacing.screen),
              child: SizedBox(
                height: 43,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recommended For You',
                    maxLines: 1,
                    style: TextStyle(
                      color: Md3Colors.text,
                      fontSize: 36,
                      height: 43 / 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Md3Spacing.x16),
          ],
        ),
      ),
    );
  }

  Widget _buildTopGenerationAction(UserState userState) {
    final label = _primaryCommandLabel(userState);
    final onPressed =
        _primaryCommandDisabled(userState) ? null : () => _runPrimaryCommand(userState);
    final icon = switch (label) {
      'Refresh Deck' || 'Try again' => Icons.refresh_rounded,
      'Watch ad for another deck' => Icons.play_circle_fill_rounded,
      _ => Icons.auto_awesome_rounded,
    };

    return Semantics(
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      label: _topGenerationSemanticLabel(label),
      onTap: onPressed,
      child: SizedBox(
        key: const Key('recommendation-top-generation-action'),
        height: Md3Targets.minimum,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Md3Colors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Md3Colors.primarySoft,
            disabledForegroundColor: Md3Colors.muted,
            padding: const EdgeInsets.symmetric(horizontal: Md3Spacing.x12),
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Md3Radius.button),
            ),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFilterBar(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.25;

    return Semantics(
      container: true,
      label: 'Recommendation filters',
      child: SizedBox(
        key: const Key('recommendation-filter-bar'),
        height: 54,
        child: Md3LiquidGlass(
          margin: const EdgeInsets.symmetric(horizontal: Md3Spacing.screen),
          padding: const EdgeInsets.all(5),
          borderRadius: BorderRadius.circular(Md3Radius.card),
          blur: Md3NavigationMetrics.compactGlassBlur,
          tint: Md3Colors.glassTint,
          borderColor: Md3Colors.glassBorderSubtle,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 290;

              return Row(
                children: [
                  Expanded(
                    flex: largeText
                        ? 3
                        : constraints.maxWidth < 290
                            ? 5
                            : 4,
                    child: _buildTypeSegment(compact: compact || largeText),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: largeText ? 7 : 3,
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
      height: Md3Targets.minimum,
      decoration: BoxDecoration(
        color: Md3Colors.surfaceMuted,
        borderRadius: BorderRadius.circular(Md3Radius.button),
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
          borderRadius: BorderRadius.circular(Md3Radius.button),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : Md3Durations.standard,
            curve: Curves.easeOut,
            height: Md3Targets.minimum,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Md3Colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(Md3Radius.button),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (compact)
                  Icon(
                    icon,
                    size: 19,
                    color: selected ? Colors.white : Md3Colors.text,
                  )
                else ...[
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? Colors.white : Md3Colors.text,
                  ),
                  const SizedBox(width: 4),
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
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.25;

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
            borderRadius: BorderRadius.circular(Md3Radius.button),
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
                    style: TextStyle(
                      color: Md3Colors.text,
                      fontSize: largeText ? 13 : 14,
                      height: largeText ? 18 / 13 : 18 / 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 2),
              const Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: Md3Colors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStaleDeckNotice() {
    final loadedSelection =
        '${_discoveryLevelLabel(deckDiscoveryLevel ?? selectedDiscoveryLevel)} ${_typeDeckLabel(deckType ?? selectedType)} deck';
    final pendingSelection =
        '${_discoveryLevelLabel(selectedDiscoveryLevel)} ${_typeDeckLabel(selectedType)} deck';

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
                'Showing $loadedSelection. Selected $pendingSelection. Build it when you’re ready.',
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

  Widget buildDeckOriginNotice() {
    final generatedAt = deckGeneratedAt?.toLocal();
    final mode = _discoveryLevelLabel(
      deckDiscoveryLevel ?? selectedDiscoveryLevel,
    );
    final media = _typeDeckLabel(deckType ?? selectedType);
    final detail = generatedAt == null
        ? '$mode $media recommendations'
        : '$mode $media recommendations • ${DateFormat('MMM d, h:mm a').format(generatedAt)}';

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: 'Saved deck. $detail.',
      child: Container(
        key: const Key('recommendation-saved-deck-notice'),
        padding: const EdgeInsets.all(Md3Spacing.x12),
        decoration: BoxDecoration(
          color: Md3Colors.surface,
          borderRadius: BorderRadius.circular(Md3Radius.card),
          border: Border.all(color: Md3Colors.border),
          boxShadow: Md3Shadows.contentCard,
        ),
        child: Row(
          children: [
            Container(
              width: Md3Targets.minimum,
              height: Md3Targets.minimum,
              decoration: BoxDecoration(
                color: Md3Colors.primarySoft,
                borderRadius: BorderRadius.circular(Md3Radius.input),
              ),
              child: const Icon(
                Icons.bookmark_added_rounded,
                color: Md3Colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: Md3Spacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saved deck',
                    style: TextStyle(
                      color: Md3Colors.text,
                      fontSize: 16,
                      height: 20 / 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Md3Colors.muted,
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
    final isDailyLimit = recommendationAllowance?.limitReached ?? false;
    final isRequestInProgress =
        recommendationAllowance?.requestInProgress ?? false;
    final title = !hasRequestedRecommendations
        ? 'Personal discovery'
        : isDailyLimit
            ? 'Fresh picks reset tomorrow'
            : isRequestInProgress
                ? 'Your deck is still building'
                : switch (failureKind) {
                    RecommendationFailureKind.timeout =>
                      'This deck took too long',
                    RecommendationFailureKind.unavailable =>
                      'Recommendations unavailable',
                    RecommendationFailureKind.cancelled => 'Discovery paused',
                    null => _lastRequestWasRefresh
                        ? 'No new recommendations available'
                        : 'No recommendations available',
                  };
    final message = !hasRequestedRecommendations
        ? 'Start a fresh recommendation deck based on your MovieDiary taste.'
        : isDailyLimit
            ? "You've used today's ${recommendationAllowance?.freeDecksPerDay ?? 2} free decks. Your saved recommendations and every tracking feature are still available. Fresh picks reset at 00:00 UTC."
            : isRequestInProgress
                ? 'The same request is already in progress. Wait a moment, then try again; it will only count after a deck is ready.'
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
                    if (isDailyLimit)
                      TextButton.icon(
                        key: const Key('recommendation-limit-history'),
                        onPressed: () => Navigator.of(context).push(
                          RouteHelper.createRoute(
                            () => const RecommendationsHistoryPage(),
                          ),
                        ),
                        icon: const Icon(Icons.history_rounded, size: 18),
                        label: const Text('View saved decks'),
                      )
                    else if (!isRequestInProgress)
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SearchStandalonePage(),
                          ),
                        ),
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Search titles'),
                      ),
                    if (!isDailyLimit &&
                        !isRequestInProgress &&
                        selectedDiscoveryLevel !=
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
                  borderRadius: BorderRadius.circular(Md3Radius.pill),
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
                        borderRadius: BorderRadius.circular(Md3Radius.button),
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

  Widget buildDeckCompletion(double bottomPadding) {
    return ListView(
      key: const Key('recommendation-deck-complete'),
      padding: EdgeInsets.fromLTRB(
        Md3Spacing.screen,
        Md3Spacing.x12,
        Md3Spacing.screen,
        bottomPadding,
      ),
      children: [
        Md3Card(
          padding: const EdgeInsets.all(Md3Spacing.x24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Md3Colors.likedSoft,
                    borderRadius: BorderRadius.circular(Md3Radius.poster),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Md3Colors.success,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: Md3Spacing.x16),
              const Text(
                'Deck complete',
                style: TextStyle(
                  color: Md3Colors.text,
                  fontSize: 24,
                  height: 29 / 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: Md3Spacing.x8),
              const Text(
                'You explored all 10 picks. Save what looks good, rate what you watch, and your next deck will keep getting sharper.',
                style: TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 16,
                  height: 23 / 16,
                ),
              ),
              const SizedBox(height: Md3Spacing.x24),
              Md3PrimaryButton(
                text: 'Explore another deck',
                icon: Icons.refresh_rounded,
                height: 52,
                onPressed:
                    isLoading ? null : () => _getRecommendations(refresh: true),
              ),
              const SizedBox(height: Md3Spacing.x8),
              SizedBox(
                height: Md3Targets.minimum,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Back to Discover'),
                ),
              ),
            ],
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
          padding: EdgeInsets.fromLTRB(
            Md3Spacing.screen,
            Md3Spacing.x12,
            Md3Spacing.screen,
            bottomPadding,
          ),
          children: [
            if (isPartialDeck) _buildPartialDeckNotice(),
            if (deckOrigin == RecommendationDeckOrigin.saved) ...[
              buildDeckOriginNotice(),
              const SizedBox(height: Md3Spacing.x12),
            ],
            _buildDeckNavigator(index),
            const SizedBox(height: Md3Spacing.x16),
            _buildRecommendationCard(context, recommendedMovies[index], index),
          ],
        );
      },
    );
  }

  Widget _buildDeckNavigator(int index) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final stackProgress = textScale >= 1.6;
    final actionInFlight = _savingMovieIds.isNotEmpty;
    final canGoPrevious = index > 0 && !isLoading && !actionInFlight;
    final canGoNext = (index < recommendedMovies.length - 1 || hasMore) &&
        !isLoading &&
        !actionInFlight;
    final canFinish = _isFullDeckCompletionBoundary(index) &&
        !isLoading &&
        !actionInFlight &&
        !_completionInFlight;
    final progress = Semantics(
      key: const Key('recommendation-progress'),
      liveRegion: true,
      label:
          'Recommendation ${index + 1} of ${recommendedMovies.length} loaded${hasMore ? '. More recommendations are available' : ''}.',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${index + 1} of ${recommendedMovies.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Md3Colors.text,
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
    final previous = _buildDeckMoveButton(
      key: const Key('recommendation-previous'),
      label: 'Previous',
      icon: Icons.arrow_back_rounded,
      showIcon: !stackProgress,
      onPressed: canGoPrevious ? () => _moveToIndex(index - 1) : null,
    );
    final next = _buildDeckMoveButton(
      key: const Key('recommendation-next'),
      label: canFinish ? 'Finish' : 'Next',
      icon: canFinish ? Icons.check_rounded : Icons.arrow_forward_rounded,
      showIcon: !stackProgress,
      iconAfterLabel: true,
      onPressed: canFinish
          ? () => _completeDeck(index)
          : canGoNext
              ? () => _moveToNext(index)
              : null,
    );

    final navigator = Md3Card(
      color: Md3Colors.surface,
      padding: const EdgeInsets.all(5),
      child: stackProgress
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                progress,
                const SizedBox(height: Md3Spacing.x8),
                Row(
                  children: [
                    Expanded(child: previous),
                    const SizedBox(width: Md3Spacing.x8),
                    Expanded(child: next),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: previous),
                SizedBox(width: 104, child: progress),
                Expanded(child: next),
              ],
            ),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Recommendation deck navigation',
      child: stackProgress
          ? navigator
          : SizedBox(
              key: const Key('recommendation-deck-navigator'),
              height: 56,
              child: navigator,
            ),
    );
  }

  Widget _buildDeckMoveButton({
    required Key key,
    required String label,
    required IconData icon,
    required bool showIcon,
    required VoidCallback? onPressed,
    bool iconAfterLabel = false,
  }) {
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.fade,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
    );
    final iconWidget = Icon(icon, size: 18);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: OutlinedButton(
        key: key,
        style: OutlinedButton.styleFrom(
          foregroundColor: Md3Colors.primary,
          disabledForegroundColor: Md3Colors.muted,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: Md3Spacing.x8),
          side: const BorderSide(color: Md3Colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Md3Radius.button),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon && !iconAfterLabel) ...[
              iconWidget,
              const SizedBox(width: 4),
            ],
            Flexible(child: labelWidget),
            if (showIcon && iconAfterLabel) ...[
              const SizedBox(width: 4),
              iconWidget,
            ],
          ],
        ),
      ),
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
    final reason = _recommendationReason(movie);
    final matchLabel = _recommendationMatchLabel(movie);

    final isSaving = _savingMovieIds.contains(movie.id);

    return Md3Card(
      key: Key('recommendation-card-$index'),
      padding: const EdgeInsets.all(Md3Spacing.card),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final useLargePhoneLayout = constraints.maxWidth >= 330;
          final posterWidth = useLargePhoneLayout
              ? 150.0
              : constraints.maxWidth >= 300
                  ? 128.0
                  : 112.0;
          final posterHeight = posterWidth * 1.5;
          final showCompactActionRow = useLargePhoneLayout &&
              textScale < 1.2 &&
              !MovieRate.isViewed(movie.movieRate) &&
              movie.movieRate != MovieRate.addedToWatchlist;
          final genresText = movie.genres.isNotEmpty
              ? movie.genres.take(3).join(', ')
              : movie.movieType == MovieType.tv
                  ? 'TV recommendation'
                  : 'Movie recommendation';
          final useInlineDetails = useLargePhoneLayout &&
              textScale < 1.2 &&
              movie.title.length <= 35 &&
              genresText.length <= 45;

          final primaryAction = _buildRecommendationPrimaryAction(
            context,
            movie,
            index,
            isSaving,
          );
          final seenAction = _buildSeenAlreadyAction(
            context,
            movie,
            isSaving,
          );

          return Column(
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
                  const SizedBox(width: Md3Spacing.x16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (MovieRate.isViewed(movie.movieRate) ||
                            movie.movieRate == MovieRate.addedToWatchlist)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: Md3Spacing.x8,
                            ),
                            child: Md3OpinionBadge(
                              movieRate: movie.movieRate,
                            ),
                          ),
                        Text(
                          movie.title,
                          style: const TextStyle(
                            color: Md3Colors.text,
                            fontSize: 22,
                            height: 26 / 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: Md3Spacing.x4),
                        if (matchLabel != null) ...[
                          Semantics(
                            label: 'Recommendation fit: $matchLabel',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: Md3Colors.primary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    matchLabel,
                                    style: const TextStyle(
                                      color: Md3Colors.primary,
                                      fontSize: 13,
                                      height: 18 / 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Md3Spacing.x4),
                        ],
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
                          genresText,
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
                        if (useInlineDetails) ...[
                          const SizedBox(height: Md3Spacing.x4),
                          _buildOpenDetailsAction(context, movie, isSaving),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Md3Spacing.x20),
              const Text(
                'Why this pick',
                style: TextStyle(
                  color: Md3Colors.text,
                  fontSize: 20,
                  height: 25 / 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: Md3Spacing.x8),
              _buildRecommendationReason(movie, reason),
              const SizedBox(height: Md3Spacing.x20),
              if (showCompactActionRow)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 3, child: primaryAction),
                    const SizedBox(width: Md3Spacing.x12),
                    Expanded(flex: 2, child: seenAction),
                  ],
                )
              else ...[
                primaryAction,
                if (!MovieRate.isViewed(movie.movieRate)) ...[
                  const SizedBox(height: Md3Spacing.x8),
                  seenAction,
                ],
              ],
              if (!useInlineDetails) ...[
                const SizedBox(height: Md3Spacing.x4),
                _buildOpenDetailsAction(context, movie, isSaving),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecommendationReason(Movie movie, String reason) {
    const style = TextStyle(
      color: Md3Colors.muted,
      fontSize: 16,
      height: 22 / 16,
    );
    final expanded = _expandedReasonMovieIds.contains(movie.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: reason, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 2,
        )..layout(maxWidth: constraints.maxWidth);
        final canCollapse = painter.didExceedMaxLines;
        painter.dispose();

        if (!canCollapse) {
          return Semantics(
            container: true,
            label: 'Why this pick: $reason',
            child: ExcludeSemantics(
              child: Text(reason, style: style),
            ),
          );
        }

        void toggleReason() {
          setState(() {
            if (expanded) {
              _expandedReasonMovieIds.remove(movie.id);
            } else {
              _expandedReasonMovieIds.add(movie.id);
            }
          });
        }

        final collapsedReason = _truncateReasonAtWordBoundary(
          reason: reason,
          style: style,
          maxWidth: (constraints.maxWidth - Md3Spacing.x48 - Md3Spacing.x16)
              .clamp(1, double.infinity)
              .toDouble(),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
        );

        return Semantics(
          key: Key('recommendation-reason-semantics-${movie.id}'),
          container: true,
          button: true,
          onTap: toggleReason,
          value: expanded ? 'Expanded' : 'Collapsed',
          label: 'Why this pick: $reason',
          hint: expanded
              ? 'Double tap to show fewer lines'
              : 'Double tap to read the full reason',
          child: ExcludeSemantics(
            child: InkWell(
              key: Key('recommendation-reason-${movie.id}'),
              onTap: toggleReason,
              borderRadius: BorderRadius.circular(Md3Radius.small),
              child: AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : Md3Durations.standard,
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            reason,
                            key: Key(
                              'recommendation-reason-text-${movie.id}',
                            ),
                            style: style,
                          ),
                          const SizedBox(height: Md3Spacing.x8),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: _buildRecommendationReasonToggle(
                              movie: movie,
                              expanded: true,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              collapsedReason,
                              key: Key(
                                'recommendation-reason-text-${movie.id}',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.clip,
                              style: style,
                            ),
                          ),
                          const SizedBox(width: Md3Spacing.x8),
                          _buildRecommendationReasonToggle(
                            movie: movie,
                            expanded: false,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationReasonToggle({
    required Movie movie,
    required bool expanded,
  }) {
    return Container(
      key: Key('recommendation-reason-toggle-${movie.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: Md3Spacing.x8,
        vertical: Md3Spacing.x4,
      ),
      decoration: BoxDecoration(
        color: Md3Colors.primarySoft,
        borderRadius: BorderRadius.circular(Md3Radius.button),
      ),
      child: Text(
        expanded ? 'Less' : 'More',
        style: const TextStyle(
          color: Md3Colors.primary,
          fontSize: 13,
          height: 22 / 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _truncateReasonAtWordBoundary({
    required String reason,
    required TextStyle style,
    required double maxWidth,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required Locale? locale,
  }) {
    final normalizedReason = reason.trim().replaceAll(RegExp(r'\s+'), ' ');
    final words = normalizedReason.split(' ');
    if (words.length <= 1) {
      return '…';
    }

    bool fits(String candidate) {
      final painter = TextPainter(
        text: TextSpan(text: candidate, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        locale: locale,
        maxLines: 2,
      )..layout(maxWidth: maxWidth);
      final fits = !painter.didExceedMaxLines;
      painter.dispose();
      return fits;
    }

    var low = 1;
    var high = words.length - 1;
    var best = 0;
    while (low <= high) {
      final midpoint = (low + high) ~/ 2;
      final candidate = '${words.take(midpoint).join(' ')}…';
      if (fits(candidate)) {
        best = midpoint;
        low = midpoint + 1;
      } else {
        high = midpoint - 1;
      }
    }

    return best == 0 ? '…' : '${words.take(best).join(' ')}…';
  }

  Widget _buildOpenDetailsAction(
    BuildContext context,
    Movie movie,
    bool isSaving,
  ) {
    return SizedBox(
      height: Md3Targets.minimum,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: Md3Colors.primary,
          minimumSize: const Size(Md3Targets.minimum, Md3Targets.minimum),
          padding: const EdgeInsets.symmetric(horizontal: Md3Spacing.x8),
        ),
        onPressed: isSaving ? null : () => _openMovieDetails(context, movie),
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        label: const Text(
          'Open details',
          maxLines: 1,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  String? _recommendationMatchLabel(Movie movie) {
    final label = movie.recommendationMatchLabel?.trim();
    if (label?.isNotEmpty == true) {
      return label;
    }

    return movie.recommendationMatchPercent > 0 ? 'Worth exploring' : null;
  }

  String _recommendationReason(Movie movie) {
    const fallback =
        'This recommendation comes from an earlier deck. Its saved reason is unavailable.';
    final reason =
        movie.recommendationReason?.replaceAll(RegExp(r'\s+'), ' ').trim() ??
            '';
    const unsafeTerms = <String>[
      'system prompt',
      'ignore previous',
      'ignore all instructions',
      'chain of thought',
      'language model',
      'openai',
      'prompt version',
      'score version',
      'recommendationpromptversion',
      'recommendationscoreversion',
      'you may enjoy',
      'perfect for fans',
      'based on your preferences',
      'production context',
      'same year',
      'same format',
      'a strong fit for your',
      'slightly broader lane',
      'quality wildcard',
      'higher-upside adventurous pick',
      'taste profile you have been building',
    ];
    final normalized = reason.toLowerCase();

    if (reason.isEmpty ||
        reason.length > 280 ||
        unsafeTerms.any(normalized.contains)) {
      return fallback;
    }

    return reason;
  }

  Widget _buildSeenAlreadyAction(
    BuildContext context,
    Movie movie,
    bool isSaving,
  ) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Md3Colors.primary,
          side: const BorderSide(color: Md3Colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Md3Radius.button),
          ),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: Md3Spacing.x8),
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
    int index,
    bool isSaving,
  ) {
    if (movie.movieRate == MovieRate.addedToWatchlist) {
      final canContinue =
          (index < recommendedMovies.length - 1 || hasMore) && !isSaving;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Md3PrimaryButton(
            text: 'Saved',
            icon: Icons.bookmark_added_rounded,
            tonal: true,
            height: 56,
          ),
          if (index < recommendedMovies.length - 1 || hasMore) ...[
            const SizedBox(height: Md3Spacing.x8),
            SizedBox(
              width: double.infinity,
              height: Md3Targets.minimum,
              child: OutlinedButton.icon(
                key: Key('recommendation-saved-next-${movie.id}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Md3Colors.primary,
                  side: const BorderSide(color: Md3Colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Md3Radius.button),
                  ),
                ),
                onPressed: canContinue ? () => _moveToNext(index) : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text(
                  'Next',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ],
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
        height: 56,
      );
    }

    return Md3PrimaryButton(
      text: isSaving ? 'Saving' : 'Add to Watchlist',
      icon: Icons.bookmark_add_rounded,
      height: 56,
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
    final deckRevision = _deckRevision;

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

        final response = await serviceAgent
            .rateMovie(
              movie.id,
              userId,
              MovieRate.addedToWatchlist,
            )
            .timeout(_mutationTimeout);
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
      movie.movieRate = previousRate;
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
    if (deckRevision != _deckRevision) {
      return;
    }
    unawaited(trackMovieStateTransition(
      movieId: movie.id,
      previousRate: previousRate,
      nextRate: MovieRate.addedToWatchlist,
      sourceSurface: 'recommendations',
    ));
    unawaited(ProductAnalytics.instance.track(
      ProductAnalyticsEventName.recommendationWatchlistAdded,
      parameters: {
        ProductAnalyticsParameter.movieId: movie.id,
        ProductAnalyticsParameter.sourceSurface: 'recommendations',
        if (sessionId != null)
          ProductAnalyticsParameter.recommendationSessionId: sessionId,
      },
      transitionId: sessionId == null ? null : '$sessionId:${movie.id}',
    ));
    MSnackBar.showWithMessenger(
      messenger,
      'Saved to Watchlist',
      true,
      duration: MSnackBar.actionDuration,
      bottomMargin: MSnackBar.actionBottomMargin,
      actionLabel: 'Undo',
      feedbackIcon: Icons.bookmark_added_rounded,
      feedbackIconColor: Md3Colors.primary,
      feedbackIconBackgroundColor: Md3Colors.primarySoft,
      onAction: () => unawaited(
        _undoWatchlistSave(
          movie: movie,
          previousRate: previousRate,
          deckRevision: deckRevision,
          messenger: messenger,
        ),
      ),
    );
  }

  Future<void> _undoWatchlistSave({
    required Movie movie,
    required int previousRate,
    required int deckRevision,
    required ScaffoldMessengerState messenger,
  }) async {
    if (!mounted ||
        deckRevision != _deckRevision ||
        _savingMovieIds.contains(movie.id) ||
        movie.movieRate != MovieRate.addedToWatchlist) {
      return;
    }

    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    setState(() => _savingMovieIds.add(movie.id));

    try {
      await moviesState.changeMovieRate(
        movie.id,
        previousRate,
        userState.isIncognitoMode,
        movie,
      );
      movie.movieRate = previousRate;

      if (!userState.isIncognitoMode) {
        final userId = userState.userId;
        if (userId == null || userId.isEmpty || ServiceAgent.state == null) {
          throw const HttpException('Signed-in movie update is unavailable.');
        }

        final response = await serviceAgent
            .rateMovie(movie.id, userId, previousRate)
            .timeout(_mutationTimeout);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException(
            'Movie update failed with ${response.statusCode}.',
          );
        }
      }
    } catch (_) {
      await moviesState.changeMovieRate(
        movie.id,
        MovieRate.addedToWatchlist,
        userState.isIncognitoMode,
        movie,
      );
      movie.movieRate = MovieRate.addedToWatchlist;
      if (!mounted) {
        return;
      }

      setState(() => _savingMovieIds.remove(movie.id));
      MSnackBar.showWithMessenger(
        messenger,
        'Couldnâ€™t undo the Watchlist save. Try again.',
        false,
        duration: const Duration(milliseconds: 2500),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _savingMovieIds.remove(movie.id));
    unawaited(trackMovieStateTransition(
      movieId: movie.id,
      previousRate: MovieRate.addedToWatchlist,
      nextRate: previousRate,
      sourceSurface: 'recommendations',
    ));
    MSnackBar.showWithMessenger(
      messenger,
      'Removed from Watchlist.',
      true,
      duration: const Duration(milliseconds: 1800),
    );
  }

  Future<void> _markSeenAlready(BuildContext context, Movie movie) async {
    if (_savingMovieIds.contains(movie.id)) {
      return;
    }

    final deckRevision = _deckRevision;
    setState(() => _savingMovieIds.add(movie.id));
    final savedRate = await showMarkWatchedBottomSheet(
      context: context,
      movie: movie,
      sourceSurface: 'recommendations',
      recommendationSessionId: sessionId,
      serviceAgent: serviceAgent,
    );

    if (!mounted) {
      return;
    }

    if (savedRate != null && deckRevision == _deckRevision) {
      await _advanceAfterAction(movie);
    }

    if (mounted) {
      setState(() => _savingMovieIds.remove(movie.id));
    }
  }

  Future<void> _openMovieDetails(BuildContext context, Movie movie) async {
    unawaited(ProductAnalytics.instance.track(
      ProductAnalyticsEventName.recommendationDetailsOpened,
      parameters: {
        ProductAnalyticsParameter.movieId: movie.id,
        ProductAnalyticsParameter.sourceSurface: 'recommendations',
        if (sessionId != null)
          ProductAnalyticsParameter.recommendationSessionId: sessionId,
      },
      transitionId: sessionId == null ? null : '$sessionId:${movie.id}',
    ));
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MovieListItemExpanded(
          movie: movie,
          imageUrl: 'https://moviediarystorage.blob.core.windows.net/movies',
          shouldRequestReview: true,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
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
    final userState = Provider.of<UserState>(context, listen: false);
    final label = _primaryCommandLabel(userState);
    final icon = switch (label) {
      'Refresh Deck' || 'Retry' => Icons.refresh_rounded,
      'Build a new deck' || 'Use extra deck' => Icons.auto_awesome_rounded,
      'Watch ad for another deck' => Icons.play_circle_fill_rounded,
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
          margin: const EdgeInsets.symmetric(horizontal: Md3Spacing.x12),
          padding: const EdgeInsets.all(Md3Spacing.x8),
          borderRadius: BorderRadius.circular(Md3Radius.card),
          blur: Md3NavigationMetrics.compactGlassBlur,
          tint: Md3Colors.glassTint,
          borderColor: Md3Colors.glassBorderSubtle,
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
                  borderRadius: BorderRadius.circular(Md3Radius.button),
                ),
              ),
              onPressed:
                  _primaryCommandDisabled(userState) ? null : () => _runPrimaryCommand(userState),
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

  String _primaryCommandLabel(UserState userState) {
    if ((recommendationAllowance?.rewardedCreditsAvailable ?? 0) > 0) {
      return 'Refresh Deck';
    }
    if (recommendationAllowance?.limitReached ?? false) {
      return 'Watch ad for another deck';
    }
    if (recommendationAllowance?.requestInProgress ?? false) {
      return 'Try again';
    }

    if (isDeckStale) {
      final typeChanged = deckType != selectedType;
      final modeChanged = deckDiscoveryLevel != selectedDiscoveryLevel;
      if (typeChanged && modeChanged) {
        return 'Build ${_discoveryLevelLabel(selectedDiscoveryLevel)} ${_typeDeckLabel(selectedType)} deck';
      }
      if (modeChanged) {
        return 'Build ${_discoveryLevelLabel(selectedDiscoveryLevel)} deck';
      }
      return 'Build ${_typeDeckLabel(selectedType)} deck';
    }

    if (deckOrigin == RecommendationDeckOrigin.saved) {
      return 'Refresh Deck';
    }

    if (recommendedMovies.isNotEmpty) {
      return 'Refresh Deck';
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

  bool _canOfferRewardedDeck(UserState userState) {
    final allowance = recommendationAllowance;
    if (allowance == null ||
        !allowance.limitReached ||
        allowance.isPremium ||
        allowance.rewardedCreditsAvailable > 0 ||
        allowance.rewardedDecksGranted >= allowance.rewardedDecksPerDay) {
      return false;
    }
    return userState.monetization
        .evaluate(
          MonetizationPlacement.extraRecommendationRewarded,
          surface: MonetizationSurface.recommendationAllowance,
        )
        .isEligible;
  }

  bool _primaryCommandDisabled(UserState userState) =>
      isButtonDisabled ||
      (_primaryCommandLabel(userState) == 'Watch ad for another deck' &&
          !_canOfferRewardedDeck(userState));

  Future<void> _runPrimaryCommand(UserState userState) async {
    final label = _primaryCommandLabel(userState);

    if (label == 'Watch ad for another deck') {
      await _presentRewardedAllowanceOffer(_requestToken);
      return;
    }

    if (label == 'Refresh Deck' &&
        (recommendationAllowance?.rewardedCreditsAvailable ?? 0) > 0) {
      await _getRecommendations(
        refresh: recommendedMovies.isNotEmpty,
        retryRequest: recommendedMovies.isEmpty ? _retryRequest : null,
      );
      return;
    }

    if (label == 'Try again') {
      await _getRecommendations(retryRequest: _retryRequest);
      return;
    }

    if (label == 'Rate more') {
      _openRatingFlow(context);
      return;
    }

    final retryRequest =
        label == 'Retry' || failureKind == RecommendationFailureKind.cancelled
            ? _retryRequest
            : null;
    await _getRecommendations(
      refresh: label == 'Refresh Deck' || label == 'Build a new deck',
      retryRequest: retryRequest,
    );
  }

  String _topGenerationSemanticLabel(String label) {
    if (!isDeckStale) {
      return label;
    }

    return '$label for the selected ${_discoveryLevelLabel(selectedDiscoveryLevel)} ${_typeDeckLabel(selectedType)} recommendations';
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
