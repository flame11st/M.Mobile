import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mmobile/Helpers/rating_helper.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/movie_list_item.dart';
import 'package:mmobile/Widgets/search_state.dart';

class SearchPage extends StatefulWidget {
  final bool isActive;
  final bool showBottomNavigationClearance;
  final bool handlesBackNavigation;
  final VoidCallback? onExitRequested;
  final MovieSearchFetcher? fetcher;

  const SearchPage({
    super.key,
    this.isActive = true,
    this.showBottomNavigationClearance = true,
    this.handlesBackNavigation = true,
    this.onExitRequested,
    this.fetcher,
  });

  @override
  State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  static const _recentSearchesKey = 'movieDiaryRecentSuccessfulSearches';
  static const _suggestionTimeout = Duration(seconds: 6);

  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _serviceAgent = ServiceAgent();
  final _storage = const FlutterSecureStorage();

  late final MovieSearchStateController _searchController;
  bool _suggestionsLoading = true;
  List<String> _popularSearches = const [];
  List<String> _recentSearches = const [];
  int? _lastRememberedRequestId;

  @override
  void initState() {
    super.initState();
    _searchController = MovieSearchStateController(
      fetcher: widget.fetcher ?? _fetchSearch,
    )..addListener(_handleSearchStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadSuggestions());
      }
    });
  }

  @override
  void didUpdateWidget(covariant SearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _focusNode.unfocus();
    }
  }

  Future<void> handleActiveTabTap() async {
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
    _searchController
      ..removeListener(_handleSearchStateChanged)
      ..dispose();
    _queryController.dispose();
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

    final content = ColoredBox(
      color: Md3Colors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Search',
                style: TextStyle(
                  color: Md3Colors.text,
                  fontSize: 32,
                  height: 1.19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Find movies and TV shows to watch, rate, or save.',
                style: TextStyle(
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
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack();
      },
      child: content,
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
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
    return ListView(
      key: const ValueKey('search-landing'),
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(16, 24, 16, bottomPadding),
      children: [
        if (_suggestionsLoading)
          const _SuggestionLoading()
        else if (_popularSearches.isNotEmpty)
          _SuggestionSection(
            title: 'Popular searches',
            body: 'Based on successful MovieDiary searches.',
            suggestions: _popularSearches,
            icon: Icons.trending_up_rounded,
            onSelected: _selectSuggestion,
          )
        else if (_recentSearches.isNotEmpty)
          _SuggestionSection(
            title: 'Recent searches',
            body: 'Successful title searches saved on this device.',
            suggestions: _recentSearches,
            icon: Icons.history_rounded,
            onSelected: _selectSuggestion,
          )
        else
          const _NoSuggestions(),
      ],
    );
  }

  Widget _buildLoading(MovieSearchState state, double bottomPadding) {
    return ListView(
      key: ValueKey('search-loading-${state.requestId}'),
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(0, 10, 0, bottomPadding),
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
      padding: EdgeInsets.only(top: 8, bottom: bottomPadding),
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
          ),
      ],
    );
  }

  Widget _buildEmpty(MovieSearchState state, double bottomPadding) {
    return ListView(
      key: ValueKey('search-empty-${state.requestId}'),
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
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
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
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
    _focusNode.requestFocus();
  }

  void _handleBack() {
    if (_focusNode.hasFocus || MediaQuery.viewInsetsOf(context).bottom > 0) {
      _focusNode.unfocus();
      return;
    }

    if (_searchController.state.query.isNotEmpty) {
      _queryController.clear();
      _searchController.clear();
      return;
    }

    widget.onExitRequested?.call();
  }

  Future<void> _loadSuggestions() async {
    var popularSearches = <String>[];

    try {
      final response =
          await _serviceAgent.getPopularSearches().timeout(_suggestionTimeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Iterable) {
          popularSearches = _normalizeSuggestions(
            decoded
                .map(
                  (item) => item is String
                      ? item
                      : item is Map<String, dynamic>
                          ? item['query']
                          : null,
                )
                .whereType<String>(),
          );
        }
      }
    } catch (_) {
      // Suggestions are optional; normal title search remains available.
    }

    final recentSearches = await _loadRecentSuccessfulSearches();
    if (!mounted) {
      return;
    }

    setState(() {
      _popularSearches = popularSearches;
      _recentSearches = recentSearches;
      _suggestionsLoading = false;
    });
  }

  Future<List<String>> _loadRecentSuccessfulSearches() async {
    try {
      final storedSearches = await _storage.read(key: _recentSearchesKey);
      if (storedSearches == null) {
        return const [];
      }
      final decoded = jsonDecode(storedSearches);
      if (decoded is! Iterable) {
        return const [];
      }
      return _normalizeSuggestions(decoded.whereType<String>());
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

    await _storage.write(
      key: _recentSearchesKey,
      value: jsonEncode(updated),
    );
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
  const SearchStandalonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Md3Colors.background,
      resizeToAvoidBottomInset: true,
      body: SearchPage(
        showBottomNavigationClearance: false,
        onExitRequested: () => Navigator.of(context).maybePop(),
      ),
    );
  }
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

  const _SuggestionSection({
    required this.title,
    required this.body,
    required this.suggestions,
    required this.icon,
    required this.onSelected,
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
            fontSize: 24,
            height: 1.17,
            fontWeight: FontWeight.w900,
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in suggestions)
              Semantics(
                button: true,
                label: 'Search for $suggestion',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: ActionChip(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Md3Colors.border),
                    ),
                    backgroundColor: Colors.white,
                    avatar: Icon(
                      icon,
                      size: 18,
                      color: Md3Colors.primary,
                    ),
                    label: Text(suggestion),
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
        ),
      ],
    );
  }
}

class _NoSuggestions extends StatelessWidget {
  const _NoSuggestions();

  @override
  Widget build(BuildContext context) {
    return const Md3Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.search_rounded, color: Md3Colors.primary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search by title to find something worth watching.',
              style: TextStyle(
                color: Md3Colors.muted,
                fontSize: 16,
                height: 1.44,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
