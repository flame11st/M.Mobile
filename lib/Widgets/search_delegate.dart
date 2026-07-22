import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Variables/variables.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:provider/provider.dart';
import '../Helpers/rating_helper.dart';
import '../Helpers/ad_manager.dart';
import 'movie_list_item.dart';

class MSearchDelegate extends SearchDelegate {
  MSearchDelegate() : super(searchFieldLabel: 'Search movies or TV shows...');

  List<Movie> foundMovies = [];
  final serviceAgent = ServiceAgent();
  final storage = const FlutterSecureStorage();
  UserState? userState;
  String? oldQuery;
  int _searchRequestId = 0;
  bool isLoading = false;
  bool isLoadingSuggestions = false;
  bool suggestionsLoaded = false;
  List<String> popularSearches = [];
  List<String> recentSearches = [];

  bool notFound = false;
  bool hasSearchError = false;
  String? searchErrorMessage;
  bool showAdvancedCard = false;
  bool isAdvanced = false;
  GlobalKey? globalKey;

  static const String recentSearchesKey = 'movieDiaryRecentSuccessfulSearches';
  static const Duration searchDebounce = Duration(milliseconds: 450);

  getResultsWidget(String query, bool isResultSearch) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      final trimmedQuery = query.trim();

      if (trimmedQuery.isEmpty) {
        if (oldQuery != '') {
          _searchRequestId++;
        }
        oldQuery = '';
        isLoading = false;
        notFound = false;
        hasSearchError = false;
        searchErrorMessage = null;
        foundMovies.clear();
      } else if (trimmedQuery != oldQuery) {
        oldQuery = trimmedQuery;
        searchMovies(context, setState);
      }

      if (ModalRoute.of(context)!.isCurrent &&
          (globalKey == null || globalKey != MyGlobals.activeKey)) {
        globalKey = GlobalKey();

        MyGlobals.activeKey = globalKey;
      }

      return Scaffold(
          backgroundColor: Md3Colors.background,
          body: Container(
              key: globalKey,
              color: Md3Colors.background,
              child: ListView(
                padding: foundMovies.isNotEmpty
                    ? const EdgeInsets.fromLTRB(0, 8, 0, 24)
                    : const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: <Widget>[
                  if (foundMovies.isEmpty &&
                      isLoading &&
                      query.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Md3ListSkeletonCard(rows: 4),
                  ],
                  if (foundMovies.isEmpty &&
                      !isLoading &&
                      !notFound &&
                      !hasSearchError)
                    _buildSearchLanding(context, setState),
                  if (foundMovies.isEmpty && hasSearchError)
                    _buildSearchError(context, setState),
                  if (foundMovies.isEmpty && notFound) _buildNoResults(context),
                  if (foundMovies.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        '${foundMovies.length} result${foundMovies.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Md3Colors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    for (final movie in foundMovies)
                      MovieListItem(movie: movie),
                  ],
                ],
              )));
    });
  }

  Widget _buildSearchLanding(BuildContext context, StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Search',
          style: TextStyle(
            color: Md3Colors.text,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Find movies and TV shows to watch, rate, or save.',
          style: TextStyle(
            color: Md3Colors.muted,
            fontSize: 16,
            height: 1.35,
          ),
        ),
        _buildSuggestionSection(context, setState),
      ],
    );
  }

  Widget _buildSuggestionSection(BuildContext context, StateSetter setState) {
    if (!suggestionsLoaded && !isLoadingSuggestions) {
      _loadSearchSuggestions(context, setState);
    }

    if (isLoadingSuggestions) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: SizedBox(
          height: 2,
          child: LinearProgressIndicator(),
        ),
      );
    }

    final suggestions =
        popularSearches.isNotEmpty ? popularSearches : recentSearches;

    if (suggestions.isEmpty) {
      return const Md3Card(
        margin: EdgeInsets.only(top: 24),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: Md3Colors.primary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search by title to find something worth watching.',
                style: TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 16,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Md3SectionHeader(
          title: popularSearches.isNotEmpty
              ? 'Popular title searches'
              : 'Your recent title searches',
        ),
        Text(
          popularSearches.isNotEmpty
              ? 'Based on real successful searches from MovieDiary.'
              : 'Only searches that returned results on this device appear here.',
          style: const TextStyle(
            color: Md3Colors.muted,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in suggestions)
              _buildSuggestionChip(context, suggestion),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String text) {
    return ActionChip(
      label: Text(text),
      avatar: Icon(
        popularSearches.isNotEmpty
            ? Icons.trending_up_rounded
            : Icons.history_rounded,
        size: 18,
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Md3Colors.border),
      labelStyle: const TextStyle(
        color: Md3Colors.text,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
      onPressed: () {
        query = text;
        oldQuery = null;
        showResults(context);
      },
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return const Md3Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.search_off_rounded, color: Md3Colors.primary),
          SizedBox(height: 12),
          Text(
            'No results found',
            style: TextStyle(
              color: Md3Colors.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try a different movie or TV title.',
            style: TextStyle(
              color: Md3Colors.muted,
              fontSize: 16,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchError(BuildContext context, StateSetter setState) {
    return Md3Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Md3Colors.danger),
          const SizedBox(height: 12),
          const Text(
            'Search unavailable',
            style: TextStyle(
              color: Md3Colors.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchErrorMessage ??
                'MovieDiary could not reach search right now.',
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 16,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Md3PrimaryButton(
            text: 'Try Again',
            icon: Icons.refresh_rounded,
            tonal: true,
            onPressed: () {
              oldQuery = null;
              setState(() {
                hasSearchError = false;
                searchErrorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  searchMovies(BuildContext context, StateSetter setStateFunction) async {
    final queryToDebounce = query.trim();
    final requestId = ++_searchRequestId;
    isLoading = true;
    notFound = false;
    hasSearchError = false;
    searchErrorMessage = null;
    foundMovies = [];

    userState ??= Provider.of<UserState>(context, listen: false);

    // Debounce
    await Future.delayed(searchDebounce);
    if (requestId != _searchRequestId || queryToDebounce != query.trim()) {
      return;
    }

    if (!userState!.isPremium &&
        userState!.aiRequestsCount % 6 == 0 &&
        ServiceAgent.showLoadingAd) {
      AdManager.showInterstitialAd();
    }

    dynamic moviesResponse;

    final encoded = Uri.encodeQueryComponent(queryToDebounce);

    try {
      if (isAdvanced) {
        moviesResponse = await serviceAgent.advancedSearch(encoded);
      } else {
        moviesResponse = await serviceAgent.search(encoded);
      }
    } catch (_) {
      if (!context.mounted ||
          requestId != _searchRequestId ||
          queryToDebounce != query.trim()) {
        return;
      }

      setStateFunction(() {
        isLoading = false;
        hasSearchError = true;
        notFound = false;
        foundMovies = [];
        searchErrorMessage =
            'Check your connection or try again after the local API is running.';
      });
      return;
    }

    if (!context.mounted ||
        requestId != _searchRequestId ||
        queryToDebounce != query.trim()) {
      return;
    }

    if (moviesResponse.statusCode == 200) {
      late final List<Movie> foundMoviesNew;
      try {
        final decoded = json.decode(moviesResponse.body);
        if (decoded is! Iterable) {
          throw const FormatException('Search response is not a list.');
        }
        foundMoviesNew = decoded.map((model) => Movie.fromJson(model)).toList();
      } catch (_) {
        setStateFunction(() {
          isLoading = false;
          foundMovies = [];
          notFound = false;
          hasSearchError = true;
          searchErrorMessage =
              'MovieDiary could not read the search response. Try again.';
        });
        return;
      }

      if (!context.mounted || requestId != _searchRequestId) {
        return;
      }

      RatingHelper.refreshMoviesRating(foundMoviesNew, context);

      setStateFunction(() {
        foundMovies = foundMoviesNew;
        notFound = foundMoviesNew.isEmpty;
        hasSearchError = false;
        searchErrorMessage = null;
        isLoading = false;
      });
      globalKey = GlobalKey();

      if (ServiceAgent.showLoadingAd) userState!.increaseAiRequestsCount();

      if (foundMovies.isNotEmpty) {
        await _rememberRecentSuccessfulSearch(queryToDebounce);
      }
    } else {
      setStateFunction(() {
        isLoading = false;
        foundMovies = [];
        notFound = false;
        hasSearchError = true;
        searchErrorMessage =
            'Search returned ${moviesResponse.statusCode}. Try again in a moment.';
      });
    }
  }

  Future<void> _loadSearchSuggestions(
      BuildContext context, StateSetter setState) async {
    // This method is kicked off while the landing state is being built. Update
    // the delegate field directly here so we do not schedule a rebuild from
    // inside that build; the async completion below performs the safe rebuild.
    isLoadingSuggestions = true;

    final loadedPopularSearches = <String>[];

    try {
      final response = await serviceAgent.getPopularSearches();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Iterable) {
          loadedPopularSearches.addAll(_normalizeSuggestions(decoded
              .map((item) => item is String
                  ? item
                  : item is Map<String, dynamic>
                      ? item['query']
                      : null)
              .whereType<String>()));
        }
      }
    } catch (_) {
      // Search suggestions are optional; title search still works without them.
    }

    final loadedRecentSearches = await _loadRecentSuccessfulSearches();

    if (!context.mounted) return;

    setState(() {
      popularSearches = loadedPopularSearches;
      recentSearches = loadedRecentSearches;
      suggestionsLoaded = true;
      isLoadingSuggestions = false;
    });
  }

  Future<List<String>> _loadRecentSuccessfulSearches() async {
    try {
      final storedSearches = await storage.read(key: recentSearchesKey);

      if (storedSearches == null) {
        return [];
      }

      final decoded = jsonDecode(storedSearches);

      if (decoded is! Iterable) {
        return [];
      }

      return _normalizeSuggestions(decoded.whereType<String>());
    } catch (_) {
      return [];
    }
  }

  Future<void> _rememberRecentSuccessfulSearch(String searchQuery) async {
    final normalizedQuery = searchQuery.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (normalizedQuery.length < 2) {
      return;
    }

    final existingSearches = await _loadRecentSuccessfulSearches();
    final updatedSearches = [
      normalizedQuery,
      ...existingSearches.where(
        (item) => item.toLowerCase() != normalizedQuery.toLowerCase(),
      ),
    ].take(6).toList();

    recentSearches = updatedSearches;

    await storage.write(
      key: recentSearchesKey,
      value: jsonEncode(updatedSearches),
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

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
      const SizedBox(
        width: 10,
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (userState != null) {
          userState!.shouldRequestReview = true;
        }

        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    RatingHelper.refreshMoviesRating(foundMovies, context);

    final resultsWidget = getResultsWidget(query, true);

    return resultsWidget;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    RatingHelper.refreshMoviesRating(foundMovies, context);

    final resultsWidget = getResultsWidget(query, false);

    return resultsWidget;
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      scaffoldBackgroundColor: Md3Colors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Md3Colors.background,
        elevation: 0,
        foregroundColor: Md3Colors.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(color: Md3Colors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: const TextStyle(
          color: Md3Colors.text,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
