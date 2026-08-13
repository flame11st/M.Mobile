import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mmobile/Helpers/rating_helper.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/movie_list_item.dart';
import 'package:mmobile/Widgets/search_state.dart';

typedef PopularSearchFetcher = Future<MovieSearchTransportResponse> Function();

abstract interface class SearchSuggestionStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class SecureSearchSuggestionStore implements SearchSuggestionStore {
  final FlutterSecureStorage _storage;

  const SecureSearchSuggestionStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class SearchPage extends StatefulWidget {
  final bool isActive;
  final bool showBottomNavigationClearance;
  final bool handlesBackNavigation;
  final VoidCallback? onExitRequested;
  final MoviesList? originatingPersonalList;
  final MovieSearchFetcher? fetcher;
  final PopularSearchFetcher? suggestionFetcher;
  final SearchSuggestionStore? suggestionStore;
  final Duration suggestionTimeout;
  final Duration suggestionRefreshThrottle;
  final List<Duration> automaticSuggestionRetryDelays;
  final DateTime Function()? clock;

  const SearchPage({
    super.key,
    this.isActive = true,
    this.showBottomNavigationClearance = true,
    this.handlesBackNavigation = true,
    this.onExitRequested,
    this.originatingPersonalList,
    this.fetcher,
    this.suggestionFetcher,
    this.suggestionStore,
    this.suggestionTimeout = const Duration(seconds: 6),
    this.suggestionRefreshThrottle = const Duration(minutes: 5),
    this.automaticSuggestionRetryDelays = const [
      Duration(seconds: 8),
      Duration(seconds: 30),
      Duration(minutes: 2),
    ],
    this.clock,
  });

  @override
  State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  static const _contentTopGap = 16.0;
  static const _recentSearchesKey = 'movieDiaryRecentSuccessfulSearches';
  static const _popularSearchesKey = 'movieDiaryPopularSearches';
  static const _popularSearchesUpdatedAtKey =
      'movieDiaryPopularSearchesUpdatedAt';

  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _serviceAgent = ServiceAgent();

  late final MovieSearchStateController _searchController;
  late final SearchSuggestionStore _suggestionStore;
  late final PopularSearchFetcher _suggestionFetcher;
  late final DateTime Function() _clock;
  late final AppLifecycleListener _appLifecycleListener;

  _SuggestionPhase _suggestionPhase = _SuggestionPhase.loading;
  List<String> _popularSearches = const [];
  List<String> _recentSearches = const [];
  bool _suggestionsRefreshing = false;
  bool _cachedSuggestionRefreshFailed = false;
  DateTime? _lastSuggestionSuccessAt;
  DateTime? _lastSuggestionAttemptAt;
  Timer? _automaticSuggestionRetryTimer;
  Timer? _keyboardDismissalBackGuardTimer;
  bool _consumeBackAfterKeyboardDismissal = false;
  bool _searchFieldWasFocused = false;
  int _suggestionRequestId = 0;
  int _automaticSuggestionRetryIndex = 0;
  int? _lastRememberedRequestId;

  @override
  void initState() {
    super.initState();
    _searchFieldWasFocused = _focusNode.hasFocus;
    _focusNode.addListener(_handleFocusChanged);
    _searchController = MovieSearchStateController(
      fetcher: widget.fetcher ?? _fetchSearch,
    )..addListener(_handleSearchStateChanged);
    _suggestionStore =
        widget.suggestionStore ?? const SecureSearchSuggestionStore();
    _suggestionFetcher =
        widget.suggestionFetcher ?? _fetchPopularSearchSuggestions;
    _clock = widget.clock ?? DateTime.now;
    _appLifecycleListener = AppLifecycleListener(
      onResume: _handleAppResume,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_restoreAndRefreshSuggestions());
      }
    });
  }

  @override
  void didUpdateWidget(covariant SearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _focusNode.unfocus();
      _searchController.cancelForTabExit();
      _automaticSuggestionRetryTimer?.cancel();
    } else if (!oldWidget.isActive && widget.isActive) {
      final searchPhase = _searchController.state.phase;
      if (searchPhase == MovieSearchPhase.debouncing ||
          searchPhase == MovieSearchPhase.loading) {
        _searchController.retry();
      }
      unawaited(_refreshSuggestionsForActiveTab());
    }
  }

  Future<void> handleActiveTabTap() async {
    unawaited(_refreshSuggestionsForActiveTab());

    if (_scrollController.hasClients && _scrollController.offset > 8) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _suggestionRequestId += 1;
    _automaticSuggestionRetryTimer?.cancel();
    _keyboardDismissalBackGuardTimer?.cancel();
    _appLifecycleListener.dispose();
    _searchController
      ..removeListener(_handleSearchStateChanged)
      ..dispose();
    _queryController.dispose();
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<MovieSearchTransportResponse> _fetchSearch(
    String encodedQuery,
    bool isAdvanced,
  ) async {
    final response = isAdvanced
        ? await _serviceAgent.advancedSearch(encodedQuery)
        : await _serviceAgent.search(encodedQuery);

    return MovieSearchTransportResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  void _handleFocusChanged() {
    if (_searchFieldWasFocused && !_focusNode.hasFocus) {
      _consumeBackAfterKeyboardDismissal = true;
      _keyboardDismissalBackGuardTimer?.cancel();
      _keyboardDismissalBackGuardTimer = Timer(
        const Duration(milliseconds: 300),
        () => _consumeBackAfterKeyboardDismissal = false,
      );
    }
    _searchFieldWasFocused = _focusNode.hasFocus;

    if (mounted) {
      setState(() {});
    }
  }

  Future<MovieSearchTransportResponse> _fetchPopularSearchSuggestions() async {
    final response = await _serviceAgent.getPopularSearches();
    return MovieSearchTransportResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  void _handleAppResume() {
    if (mounted && widget.isActive) {
      unawaited(_refreshSuggestionsForActiveTab());
    }
  }

  void _handleSearchStateChanged() {
    if (!mounted) {
      return;
    }

    final state = _searchController.state;
    final announcement = _searchController.takePendingAnnouncement();
    final isTerminal = state.phase == MovieSearchPhase.results ||
        state.phase == MovieSearchPhase.empty ||
        state.phase == MovieSearchPhase.timeout ||
        state.phase == MovieSearchPhase.error;

    if (isTerminal) {
      _focusNode.unfocus();
    }

    if (state.phase == MovieSearchPhase.results &&
        state.requestId != _lastRememberedRequestId) {
      _lastRememberedRequestId = state.requestId;
      unawaited(_rememberRecentSuccessfulSearch(state.query));
    }

    setState(() {});

    if (announcement != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        SemanticsService.sendAnnouncement(
          View.of(context),
          announcement,
          Directionality.of(context),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _searchController.state;
    final isNested = widget.onExitRequested != null;
    final keyboardVisible =
        _focusNode.hasFocus || MediaQuery.viewInsetsOf(context).bottom > 0;

    final content = ColoredBox(
      color: Md3Colors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(isNested: isNested),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.originatingPersonalList == null
                    ? 'Find movies and TV shows to watch, rate, or save.'
                    : 'Add movies and TV shows to '
                        '“${widget.originatingPersonalList!.name}”.',
                style: const TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 16,
                  height: 1.44,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSearchField(state),
            Expanded(child: _buildStateBody(state)),
          ],
        ),
      ),
    );

    if (!widget.handlesBackNavigation) {
      return content;
    }

    return PopScope(
      canPop: isNested && !keyboardVisible,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack();
      },
      child: content,
    );
  }

  Widget _buildHeader({required bool isNested}) {
    const title = Text(
      'Search',
      style: TextStyle(
        color: Md3Colors.text,
        fontSize: 32,
        height: 1.19,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
    );

    if (!isNested) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: title,
      );
    }

    final destination = widget.originatingPersonalList?.name.trim();
    final tooltip = destination == null || destination.isEmpty
        ? 'Back'
        : 'Back to $destination';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              key: const ValueKey('standalone-search-back'),
              tooltip: tooltip,
              style: IconButton.styleFrom(
                backgroundColor: Md3Colors.surface,
                foregroundColor: Md3Colors.primary,
                minimumSize: const Size(48, 48),
                maximumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
                side: const BorderSide(color: Md3Colors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: widget.onExitRequested,
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(child: title),
        ],
      ),
    );
  }

  Widget _buildSearchField(MovieSearchState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 48,
        child: TextField(
          controller: _queryController,
          focusNode: _focusNode,
          autofocus: false,
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.text,
          cursorColor: Md3Colors.primary,
          style: const TextStyle(
            color: Md3Colors.text,
            fontSize: 16,
            height: 1.31,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Search movies & TV',
            hintStyle: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 16,
              height: 1.31,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 20,
              color: Md3Colors.primary,
            ),
            suffixIcon: state.query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    onPressed: _clearSearch,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Md3Colors.muted,
                    ),
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Md3Colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Md3Colors.primary,
                width: 1.5,
              ),
            ),
          ),
          onChanged: _searchController.onQueryChanged,
          onSubmitted: (_) => _searchController.retry(),
        ),
      ),
    );
  }

  Widget _buildStateBody(MovieSearchState state) {
    final bottomPadding = widget.showBottomNavigationClearance
        ? Md3NavigationMetrics.contentBottomInset(context)
        : 24.0 + MediaQuery.paddingOf(context).bottom;
    final switchDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return AnimatedSwitcher(
      duration: switchDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: switch (state.phase) {
        MovieSearchPhase.landing => _buildLanding(bottomPadding),
        MovieSearchPhase.debouncing ||
        MovieSearchPhase.loading =>
          _buildLoading(state, bottomPadding),
        MovieSearchPhase.results => _buildResults(state, bottomPadding),
        MovieSearchPhase.empty => _buildEmpty(state, bottomPadding),
        MovieSearchPhase.timeout => _buildTerminalState(
            key: const ValueKey('search-timeout'),
            title: 'Search is taking too long',
            body: 'Check your connection and try again.',
            icon: Icons.schedule_rounded,
            bottomPadding: bottomPadding,
          ),
        MovieSearchPhase.error => _buildTerminalState(
            key: const ValueKey('search-error'),
            title: 'Search unavailable',
            body: state.message ?? 'Check your connection and try again.',
            icon: Icons.wifi_off_rounded,
            bottomPadding: bottomPadding,
          ),
      },
    );
  }

  Widget _buildLanding(double bottomPadding) {
    final sections = <Widget>[
      switch (_suggestionPhase) {
        _SuggestionPhase.loading => const _SuggestionLoading(),
        _SuggestionPhase.loaded => _SuggestionSection(
            title: 'Popular searches',
            body: 'Trending successful title searches from the past 30 days.',
            suggestions: _popularSearches,
            icon: Icons.trending_up_rounded,
            onSelected: _selectSuggestion,
            isRefreshing: _suggestionsRefreshing,
            refreshFailed: _cachedSuggestionRefreshFailed,
            onRetry: _retrySuggestions,
          ),
        _SuggestionPhase.empty => _SuggestionStatusCard(
            key: const ValueKey('popular-suggestions-empty'),
            icon: Icons.trending_up_rounded,
            title: 'Popular searches are still building',
            body: 'They’ll appear after more successful MovieDiary searches.',
            actionLabel: 'Search a title',
            actionIcon: Icons.search_rounded,
            onAction: _focusNode.requestFocus,
          ),
        _SuggestionPhase.error => _SuggestionStatusCard(
            key: const ValueKey('popular-suggestions-error'),
            icon: Icons.wifi_off_rounded,
            title: 'Popular searches unavailable',
            body: 'Check your connection, then try again.',
            actionLabel: 'Retry suggestions',
            actionIcon: Icons.refresh_rounded,
            onAction: _retrySuggestions,
            isError: true,
          ),
      },
    ];

    if (_recentSearches.isNotEmpty) {
      sections
        ..add(const SizedBox(height: 24))
        ..add(
          _SuggestionSection(
            title: 'Recent searches',
            body: 'Successful title searches saved on this device.',
            suggestions: _recentSearches,
            icon: Icons.history_rounded,
            onSelected: _selectSuggestion,
          ),
        );
    }

    return ListView(
      key: const ValueKey('search-landing'),
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        16,
        _contentTopGap,
        16,
        bottomPadding,
      ),
      children: sections,
    );
  }

  Widget _buildLoading(MovieSearchState state, double bottomPadding) {
    return ListView(
      key: ValueKey('search-loading-${state.requestId}'),
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(0, _contentTopGap, 0, bottomPadding),
      children: [
        Semantics(
          liveRegion: true,
          label: 'Searching for ${state.query}',
          child: const Md3ListSkeletonCard(
            rows: 4,
            trailingSize: 44,
          ),
        ),
      ],
    );
  }

  Widget _buildResults(MovieSearchState state, double bottomPadding) {
    RatingHelper.refreshMoviesRating(state.movies, context);

    return ListView(
      key: ValueKey('search-results-${state.requestId}'),
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        top: _contentTopGap,
        bottom: bottomPadding,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            '${state.movies.length} result${state.movies.length == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 13,
              height: 1.38,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final movie in state.movies)
          MovieListItem(
            key: ValueKey('search-result-${movie.id}'),
            movie: movie,
            preferredPersonalList: widget.originatingPersonalList,
          ),
      ],
    );
  }

  Widget _buildEmpty(MovieSearchState state, double bottomPadding) {
    return ListView(
      key: ValueKey('search-empty-${state.requestId}'),
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        16,
        _contentTopGap,
        16,
        bottomPadding,
      ),
      children: [
        Md3Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.search_off_rounded,
                color: Md3Colors.primary,
                size: 28,
              ),
              const SizedBox(height: 12),
              const Text(
                'No titles found',
                style: TextStyle(
                  color: Md3Colors.text,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check the spelling or try a shorter title.',
                style: TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 16,
                  height: 1.44,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Md3Colors.primary,
                  ),
                  onPressed: _focusNode.requestFocus,
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  label: const Text('Edit search'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTerminalState({
    required Key key,
    required String title,
    required String body,
    required IconData icon,
    required double bottomPadding,
  }) {
    return ListView(
      key: key,
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        16,
        _contentTopGap,
        16,
        bottomPadding,
      ),
      children: [
        Md3Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Md3Colors.danger, size: 28),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Md3Colors.text,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: const TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 16,
                  height: 1.44,
                ),
              ),
              const SizedBox(height: 16),
              Md3PrimaryButton(
                text: 'Retry',
                icon: Icons.refresh_rounded,
                tonal: true,
                height: 48,
                onPressed: _searchController.retry,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Md3Colors.primary,
                  ),
                  onPressed: _clearSearch,
                  child: const Text('Clear search'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectSuggestion(String suggestion) {
    _queryController
      ..text = suggestion
      ..selection = TextSelection.collapsed(offset: suggestion.length);
    _focusNode.unfocus();
    _searchController.onQueryChanged(suggestion);
  }

  void _clearSearch() {
    _queryController.clear();
    _searchController.clear();
    unawaited(_refreshSuggestionsForActiveTab());
    _focusNode.requestFocus();
  }

  void _handleBack() {
    if (_focusNode.hasFocus || MediaQuery.viewInsetsOf(context).bottom > 0) {
      _focusNode.unfocus();
      _consumeBackAfterKeyboardDismissal = false;
      _keyboardDismissalBackGuardTimer?.cancel();
      return;
    }

    // Some Android IMEs clear focus immediately before Flutter receives the
    // route-pop callback. Consume that same Back event instead of letting it
    // dismiss both the keyboard and this nested Search route.
    if (_consumeBackAfterKeyboardDismissal) {
      _consumeBackAfterKeyboardDismissal = false;
      _keyboardDismissalBackGuardTimer?.cancel();
      return;
    }

    if (widget.onExitRequested != null) {
      widget.onExitRequested!.call();
      return;
    }

    if (_searchController.state.query.isNotEmpty) {
      _queryController.clear();
      _searchController.clear();
      unawaited(_refreshSuggestionsForActiveTab());
      return;
    }

    widget.onExitRequested?.call();
  }

  Future<void> _restoreAndRefreshSuggestions() async {
    String? cachedPopular;
    String? cachedUpdatedAt;
    String? cachedRecent;

    try {
      final storedValues = await Future.wait<String?>([
        _suggestionStore.read(_popularSearchesKey),
        _suggestionStore.read(_popularSearchesUpdatedAtKey),
        _suggestionStore.read(_recentSearchesKey),
      ]);
      cachedPopular = storedValues[0];
      cachedUpdatedAt = storedValues[1];
      cachedRecent = storedValues[2];
    } catch (_) {
      // A storage failure should not prevent an online suggestions refresh.
    }

    final popularSearches = _decodeStoredSuggestions(cachedPopular);
    final recentSearches = _decodeStoredSuggestions(cachedRecent);
    final lastSuccessfulAt = DateTime.tryParse(cachedUpdatedAt ?? '');

    if (!mounted) {
      return;
    }

    setState(() {
      _popularSearches = popularSearches;
      _recentSearches = recentSearches;
      _lastSuggestionSuccessAt = lastSuccessfulAt;
      _suggestionPhase = popularSearches.isNotEmpty
          ? _SuggestionPhase.loaded
          : lastSuccessfulAt == null
              ? _SuggestionPhase.loading
              : _SuggestionPhase.empty;
    });

    if (widget.isActive) {
      await _refreshPopularSuggestions(force: false);
    }
  }

  Future<void> _refreshSuggestionsForActiveTab() async {
    if (!mounted || !widget.isActive) {
      return;
    }

    final hasFailed = _suggestionPhase == _SuggestionPhase.error ||
        _cachedSuggestionRefreshFailed;
    await _refreshPopularSuggestions(force: hasFailed);
  }

  void _retrySuggestions() {
    unawaited(_refreshPopularSuggestions(force: true));
  }

  Future<void> _refreshPopularSuggestions({required bool force}) async {
    if (!mounted || !widget.isActive || _suggestionsRefreshing) {
      return;
    }

    final now = _clock();
    final lastSuccessAt = _lastSuggestionSuccessAt;
    if (!force &&
        lastSuccessAt != null &&
        now.difference(lastSuccessAt) < widget.suggestionRefreshThrottle) {
      return;
    }

    final lastAttemptAt = _lastSuggestionAttemptAt;
    if (!force &&
        lastAttemptAt != null &&
        now.difference(lastAttemptAt) < const Duration(seconds: 1)) {
      return;
    }

    _automaticSuggestionRetryTimer?.cancel();
    _lastSuggestionAttemptAt = now;
    final requestId = ++_suggestionRequestId;
    final hasCachedPopular = _popularSearches.isNotEmpty;
    final wasRecoveringFromFailure =
        _suggestionPhase == _SuggestionPhase.error ||
            _cachedSuggestionRefreshFailed;

    setState(() {
      _suggestionsRefreshing = true;
      _cachedSuggestionRefreshFailed = false;
      if (!hasCachedPopular) {
        _suggestionPhase = _SuggestionPhase.loading;
      }
    });

    MovieSearchTransportResponse response;
    try {
      response = await _suggestionFetcher().timeout(widget.suggestionTimeout);
    } catch (_) {
      _finishSuggestionFailure(requestId);
      return;
    }

    if (!mounted || requestId != _suggestionRequestId) {
      return;
    }

    if (response.statusCode != 200) {
      _finishSuggestionFailure(requestId);
      return;
    }

    List<String> popularSearches;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Iterable) {
        _finishSuggestionFailure(requestId);
        return;
      }
      popularSearches = _normalizeSuggestions(
        decoded
            .map(
              (item) => item is String
                  ? item
                  : item is Map
                      ? item['query'] ?? item['Query']
                      : null,
            )
            .whereType<String>(),
      );
    } catch (_) {
      _finishSuggestionFailure(requestId);
      return;
    }

    final successfulAt = _clock();
    _automaticSuggestionRetryTimer?.cancel();
    _automaticSuggestionRetryIndex = 0;

    setState(() {
      _popularSearches = popularSearches;
      _suggestionPhase = popularSearches.isEmpty
          ? _SuggestionPhase.empty
          : _SuggestionPhase.loaded;
      _suggestionsRefreshing = false;
      _cachedSuggestionRefreshFailed = false;
      _lastSuggestionSuccessAt = successfulAt;
    });

    unawaited(_persistPopularSuggestions(popularSearches, successfulAt));
    if (wasRecoveringFromFailure && popularSearches.isNotEmpty) {
      _announceSuggestionRecovery();
    }
  }

  void _finishSuggestionFailure(int requestId) {
    if (!mounted || requestId != _suggestionRequestId) {
      return;
    }

    final hasCachedPopular = _popularSearches.isNotEmpty;
    setState(() {
      _suggestionsRefreshing = false;
      _cachedSuggestionRefreshFailed = hasCachedPopular;
      if (!hasCachedPopular) {
        _suggestionPhase = _SuggestionPhase.error;
      }
    });
    _scheduleAutomaticSuggestionRetry();
  }

  void _scheduleAutomaticSuggestionRetry() {
    _automaticSuggestionRetryTimer?.cancel();
    if (!widget.isActive || widget.automaticSuggestionRetryDelays.isEmpty) {
      return;
    }

    final retryDelays = widget.automaticSuggestionRetryDelays;
    final retryIndex =
        _automaticSuggestionRetryIndex.clamp(0, retryDelays.length - 1).toInt();
    final retryDelay = retryDelays[retryIndex];
    if (_automaticSuggestionRetryIndex < retryDelays.length - 1) {
      _automaticSuggestionRetryIndex += 1;
    }

    _automaticSuggestionRetryTimer = Timer(retryDelay, () {
      if (!mounted ||
          !widget.isActive ||
          (_suggestionPhase != _SuggestionPhase.error &&
              !_cachedSuggestionRefreshFailed)) {
        return;
      }
      unawaited(_refreshPopularSuggestions(force: true));
    });
  }

  Future<void> _persistPopularSuggestions(
    List<String> suggestions,
    DateTime successfulAt,
  ) async {
    try {
      await Future.wait([
        _suggestionStore.write(
          _popularSearchesKey,
          jsonEncode(suggestions),
        ),
        _suggestionStore.write(
          _popularSearchesUpdatedAtKey,
          successfulAt.toUtc().toIso8601String(),
        ),
      ]);
    } catch (_) {
      // The live suggestions remain usable even if local caching is unavailable.
    }
  }

  void _announceSuggestionRecovery() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Popular searches available',
        Directionality.of(context),
      );
    });
  }

  Future<List<String>> _loadRecentSuccessfulSearches() async {
    try {
      return _decodeStoredSuggestions(
        await _suggestionStore.read(_recentSearchesKey),
      );
    } catch (_) {
      return const [];
    }
  }

  Future<void> _rememberRecentSuccessfulSearch(String query) async {
    final normalized = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length < 2) {
      return;
    }

    final existing = await _loadRecentSuccessfulSearches();
    final updated = [
      normalized,
      ...existing.where(
        (item) => item.toLowerCase() != normalized.toLowerCase(),
      ),
    ].take(6).toList(growable: false);

    if (mounted) {
      setState(() {
        _recentSearches = updated;
      });
    }

    try {
      await _suggestionStore.write(
        _recentSearchesKey,
        jsonEncode(updated),
      );
    } catch (_) {
      // Recent searches are a convenience; live search still completed.
    }
  }

  List<String> _decodeStoredSuggestions(String? encodedSuggestions) {
    if (encodedSuggestions == null) {
      return const [];
    }

    try {
      final decoded = jsonDecode(encodedSuggestions);
      if (decoded is! Iterable) {
        return const [];
      }
      return _normalizeSuggestions(decoded.whereType<String>());
    } catch (_) {
      return const [];
    }
  }

  List<String> _normalizeSuggestions(Iterable<String> suggestions) {
    final normalizedKeys = <String>{};
    final result = <String>[];

    for (final suggestion in suggestions) {
      final display = suggestion.trim().replaceAll(RegExp(r'\s+'), ' ');
      final key = display.toLowerCase();
      if (display.length < 2 ||
          display.length > 80 ||
          RegExp(r'[\u0000-\u001F\u007F]').hasMatch(display) ||
          !normalizedKeys.add(key)) {
        continue;
      }

      result.add(display);
      if (result.length == 6) {
        break;
      }
    }

    return result;
  }
}

class SearchStandalonePage extends StatelessWidget {
  final MoviesList? originatingPersonalList;
  final MovieSearchFetcher? fetcher;
  final PopularSearchFetcher? suggestionFetcher;
  final SearchSuggestionStore? suggestionStore;
  final List<Duration> automaticSuggestionRetryDelays;

  const SearchStandalonePage({
    super.key,
    this.originatingPersonalList,
    this.fetcher,
    this.suggestionFetcher,
    this.suggestionStore,
    this.automaticSuggestionRetryDelays = const [
      Duration(seconds: 8),
      Duration(seconds: 30),
      Duration(minutes: 2),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Md3Colors.background,
      resizeToAvoidBottomInset: true,
      body: SearchPage(
        showBottomNavigationClearance: false,
        originatingPersonalList: originatingPersonalList,
        fetcher: fetcher,
        suggestionFetcher: suggestionFetcher,
        suggestionStore: suggestionStore,
        automaticSuggestionRetryDelays: automaticSuggestionRetryDelays,
        onExitRequested: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

enum _SuggestionPhase {
  loading,
  loaded,
  empty,
  error,
}

class _SuggestionLoading extends StatelessWidget {
  const _SuggestionLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading search suggestions',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Md3SkeletonBox(width: 156, height: 22, radius: 10),
          SizedBox(height: 12),
          Md3SkeletonBox(height: 16, radius: 8),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Md3SkeletonBox(width: 104, height: 44, radius: 16),
              Md3SkeletonBox(width: 132, height: 44, radius: 16),
              Md3SkeletonBox(width: 116, height: 44, radius: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionSection extends StatelessWidget {
  final String title;
  final String body;
  final List<String> suggestions;
  final IconData icon;
  final ValueChanged<String> onSelected;
  final bool isRefreshing;
  final bool refreshFailed;
  final VoidCallback? onRetry;

  const _SuggestionSection({
    required this.title,
    required this.body,
    required this.suggestions,
    required this.icon,
    required this.onSelected,
    this.isRefreshing = false,
    this.refreshFailed = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Md3Colors.text,
            fontSize: 20,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(
            color: Md3Colors.muted,
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRefreshing) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            label: 'Refreshing popular searches',
            child: const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: Md3Colors.primary,
                backgroundColor: Md3Colors.primarySoft,
              ),
            ),
          ),
        ] else if (refreshFailed && onRetry != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Showing saved suggestions. Refresh when you’re back online.',
                  style: TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 13,
                    height: 1.38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Md3Colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in suggestions)
                  Semantics(
                    button: true,
                    label: 'Search for $suggestion',
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: 44,
                        maxWidth: constraints.maxWidth,
                      ),
                      child: ActionChip(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Md3Colors.border),
                        ),
                        color: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.pressed)) {
                            return Md3Colors.primary.withValues(alpha: 0.12);
                          }
                          return Colors.white;
                        }),
                        surfaceTintColor: Colors.transparent,
                        pressElevation: 0,
                        avatar: Icon(
                          icon,
                          size: 18,
                          color: Md3Colors.primary,
                        ),
                        label: Text(
                          suggestion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        labelStyle: const TextStyle(
                          color: Md3Colors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        onPressed: () => onSelected(suggestion),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SuggestionStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  final bool isError;

  const _SuggestionStatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Md3Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isError ? Md3Colors.danger : Md3Colors.primary,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Md3Colors.text,
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 14,
              height: 1.43,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Md3PrimaryButton(
            text: actionLabel,
            icon: actionIcon,
            tonal: true,
            height: 48,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
