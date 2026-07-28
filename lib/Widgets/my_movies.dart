import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Objects/user.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:provider/provider.dart';
import 'movie_list.dart';
import 'discover_page.dart';
import 'movies_lists_page.dart';
import 'onboarding_wizard_page.dart';
import 'root_navigation_shell.dart';
import 'search_page.dart';
import 'Settings.dart';
import 'Providers/loader_state.dart';
import 'Providers/movies_state.dart';
import 'Providers/user_state.dart';
import 'Shared/md3_ui.dart';

class MyMovies extends StatefulWidget {
  final int initialNavigationIndex;
  final ValueChanged<int>? onNavigationIndexChanged;

  const MyMovies({
    super.key,
    this.initialNavigationIndex = 0,
    this.onNavigationIndexChanged,
  });

  @override
  State<StatefulWidget> createState() {
    return MyMoviesState();
  }
}

class MyMoviesState extends State<MyMovies> {
  final serviceAgent = ServiceAgent();
  static const _cacheLoadTimeout = Duration(seconds: 3);
  static const _remoteRefreshTimeout = Duration(seconds: 8);
  final _visitedTabs = <bool>[true, false, false, false, false];
  final _discoverKey = GlobalKey<DiscoverPageState>();
  final _searchKey = GlobalKey<SearchPageState>();
  final _myMoviesKey = GlobalKey<MovieListState>();
  final _listsKey = GlobalKey<MoviesListsPageState>();
  final _settingsKey = GlobalKey<SettingsState>();
  bool initialDataLoaded = false;
  bool _initializationInFlight = false;
  bool _refreshInFlight = false;
  bool _retainOnboardingDuringExit = false;
  String? _refreshError;

  int selectedNavigationIndex = 0;

  bool _isSuccessfulJsonResponse(String body, int statusCode) {
    return statusCode >= 200 && statusCode < 300 && body.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    selectedNavigationIndex =
        widget.initialNavigationIndex.clamp(0, _visitedTabs.length - 1);
    _visitedTabs[selectedNavigationIndex] = true;

    Future.microtask(() {
      if (mounted) {
        setUserData();
      }
    });
  }

  Future<bool> _refreshUserMovies() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final loaderState = Provider.of<LoaderState>(context, listen: false);
    final userId = userState.userId;

    if (userId == null || userId.isEmpty) {
      return false;
    }

    final moviesResponse = await serviceAgent.getUserMovies(userId);
    final responseBody = moviesResponse.body.trim();

    if (!_isSuccessfulJsonResponse(responseBody, moviesResponse.statusCode)) {
      debugPrint('User movies load skipped: ${moviesResponse.statusCode}');
      if (userState.isIncognitoMode) {
        await _refreshCachedAnonymousMovieMetadata(moviesState);
        _syncCachedAnonymousRatings(moviesState, userState);
      }
      if (loaderState.isLoaderVisible) {
        loaderState.setIsLoaderVisible(false);
      }
      return false;
    }

    Iterable iterableMovies;
    try {
      final decodedBody = json.decode(responseBody);
      if (decodedBody is! Iterable) {
        debugPrint('User movies response was not a list.');
        if (loaderState.isLoaderVisible) {
          loaderState.setIsLoaderVisible(false);
        }
        return false;
      }

      iterableMovies = decodedBody;
    } on FormatException catch (error) {
      debugPrint('User movies response was not valid JSON: $error');
      if (loaderState.isLoaderVisible) {
        loaderState.setIsLoaderVisible(false);
      }
      return false;
    }

    final movies = iterableMovies.map((model) {
      return Movie.fromJson(model);
    }).toList();

    if (userState.isIncognitoMode &&
        movies.isEmpty &&
        moviesState.userMovies.isNotEmpty) {
      _syncCachedAnonymousRatings(moviesState, userState);
    } else {
      await moviesState.setUserMovies(movies);
    }

    final ratedMoviesCount = moviesState.userMovies
        .where((movie) => MovieRate.isViewed(movie.movieRate))
        .length;
    await userState.markLibraryRefreshSucceeded(ratedMoviesCount);

    if (loaderState.isLoaderVisible) {
      loaderState.setIsLoaderVisible(false);
    }

    return true;
  }

  Future<void> _refreshCachedAnonymousMovieMetadata(
    MoviesState moviesState,
  ) async {
    final moviesIds = moviesState.cachedUserMovies.map((e) => e.id).toList();
    if (moviesIds.isEmpty) {
      return;
    }

    var encodedIds = json.encode(moviesIds);

    final moviesResponse = await serviceAgent.getMoviesByIds(encodedIds);
    final responseBody = moviesResponse.body.trim();

    if (!_isSuccessfulJsonResponse(responseBody, moviesResponse.statusCode)) {
      debugPrint(
        'Incognito user movies load skipped: ${moviesResponse.statusCode}',
      );
      return;
    }

    Iterable iterableMovies;
    try {
      final decodedBody = json.decode(responseBody);
      if (decodedBody is! Iterable) {
        debugPrint('Incognito user movies response was not a list.');
        return;
      }

      iterableMovies = decodedBody;
    } on FormatException catch (error) {
      debugPrint('Incognito user movies response was not valid JSON: $error');
      return;
    }

    if (iterableMovies.isNotEmpty) {
      List<Movie> movies = iterableMovies.map((model) {
        return Movie.fromJson(model);
      }).toList();

      moviesState.updateUserMoviesIncognito(movies);
    }
  }

  void _syncCachedAnonymousRatings(
    MoviesState moviesState,
    UserState userState,
  ) {
    final userId = userState.userId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    var queuedCount = 0;
    for (final movie in moviesState.userMovies) {
      if (movie.movieRate == MovieRate.notRated) {
        continue;
      }

      moviesState.queueAnonymousRatingSync(movie.id, movie.movieRate);
      queuedCount += 1;
    }

    if (queuedCount > 0) {
      debugPrint(
        'Queued $queuedCount cached anonymous rating(s) for background sync.',
      );
      unawaited(moviesState.retryPendingAnonymousRatingSyncs());
    }
  }

  Future<bool> setMoviesLists() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);

    final moviesListsResponse =
        await serviceAgent.getMoviesLists(userState.userId!);
    final responseBody = moviesListsResponse.body.trim();

    if (moviesListsResponse.statusCode < 200 ||
        moviesListsResponse.statusCode >= 300 ||
        responseBody.isEmpty) {
      debugPrint(
        'Movies lists load skipped: ${moviesListsResponse.statusCode}',
      );
      moviesState.markMoviesListsRequestFinished();
      return false;
    }

    Iterable iterableMoviesLists;
    try {
      final decodedBody = json.decode(responseBody);
      if (decodedBody is! Iterable) {
        debugPrint('Movies lists response was not a list.');
        moviesState.markMoviesListsRequestFinished();
        return false;
      }

      iterableMoviesLists = decodedBody;
    } on FormatException catch (error) {
      debugPrint('Movies lists response was not valid JSON: $error');
      moviesState.markMoviesListsRequestFinished();
      return false;
    }

    final moviesLists = iterableMoviesLists.map((model) {
      var list = json.decode(model);
      return MoviesList.fromJson(list);
    }).toList();

    if (userState.isIncognitoMode) {
      moviesState.setInitialMoviesListsIncognito(moviesLists);
    } else {
      moviesState.setInitialMoviesLists(moviesLists);
    }

    return true;
  }

  Future<void> setUserInfo() async {
    final userState = Provider.of<UserState>(context, listen: false);

    if (userState.isIncognitoMode) {
      return;
    }

    if (userState.userId != null && userState.userId!.isNotEmpty) {
      final userInfoResponse =
          await serviceAgent.getUserInfo(userState.userId!);
      final responseBody = userInfoResponse.body.trim();

      if (!_isSuccessfulJsonResponse(
        responseBody,
        userInfoResponse.statusCode,
      )) {
        debugPrint('User info load skipped: ${userInfoResponse.statusCode}');
        return;
      }

      try {
        final decodedBody = json.decode(responseBody);
        if (decodedBody is! Map<String, dynamic>) {
          debugPrint('User info response was not an object.');
          return;
        }

        final user = User.fromJson(decodedBody);
        await userState.setUser(user);
      } on FormatException catch (error) {
        debugPrint('User info response was not valid JSON: $error');
      }
    }
  }

  Future<void> setUserData() async {
    if (_initializationInFlight) {
      return;
    }

    _initializationInFlight = true;
    final loaderState = Provider.of<LoaderState>(context, listen: false);
    final moviesState = Provider.of<MoviesState>(context, listen: false);

    if (mounted) {
      setState(() {
        initialDataLoaded = false;
      });
    }

    try {
      await moviesState.setInitialData().timeout(_cacheLoadTimeout);
    } on TimeoutException catch (error) {
      debugPrint('Cached library load timed out: $error');
      _refreshError =
          'MovieDiary could not read all saved data on this device.';
    } catch (error, stackTrace) {
      debugPrint('Cached library load failed: $error');
      debugPrint('$stackTrace');
      _refreshError =
          'MovieDiary could not read all saved data on this device.';
    } finally {
      _initializationInFlight = false;
      if (loaderState.isLoaderVisible) {
        loaderState.setIsLoaderVisible(false);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      initialDataLoaded = true;
    });

    unawaited(_refreshRemoteData());
  }

  Future<void> _refreshRemoteData() async {
    if (_refreshInFlight) {
      return;
    }

    _refreshInFlight = true;
    if (mounted) {
      setState(() {});
    }

    final userInfoFuture = _runRefreshTask('User info', () async {
      await setUserInfo();
      return true;
    });
    final listsFuture = _runRefreshTask('Movies lists', () => setMoviesLists());
    final starterDeckFuture =
        _runRefreshTask('Starter deck', _loadStarterDeckInBackground);
    final librarySucceeded =
        await _runRefreshTask('Library', _refreshUserMovies);

    final sideResults =
        await Future.wait([userInfoFuture, listsFuture, starterDeckFuture]);

    if (!mounted) {
      return;
    }

    final moviesState = Provider.of<MoviesState>(context, listen: false);
    if (!sideResults[1]) {
      moviesState.markMoviesListsRequestFinished();
    }
    if (!sideResults[2]) {
      moviesState.markStarterDeckRequestFinished();
    }

    setState(() {
      _refreshInFlight = false;
      _refreshError = librarySucceeded
          ? null
          : 'MovieDiary could not refresh your library.';
    });
  }

  Future<bool> _runRefreshTask(
    String label,
    Future<bool> Function() task,
  ) async {
    try {
      return await task().timeout(_remoteRefreshTimeout);
    } catch (error, stackTrace) {
      debugPrint('$label refresh failed: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<bool> _loadStarterDeckInBackground() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    if (moviesState.starterDeckMovies.isNotEmpty) {
      return true;
    }

    try {
      final response = await serviceAgent
          .getStarterDeck(perBucket: 20)
          .timeout(_remoteRefreshTimeout);
      final responseBody = response.body.trim();

      if (!_isSuccessfulJsonResponse(responseBody, response.statusCode)) {
        debugPrint('Starter deck load skipped: ${response.statusCode}');
        moviesState.markStarterDeckRequestFinished();
        return false;
      }

      final decodedBody = json.decode(responseBody);
      if (decodedBody is! Iterable) {
        debugPrint('Starter deck response was not a list.');
        moviesState.markStarterDeckRequestFinished();
        return false;
      }

      final movies = decodedBody
          .map((model) => Movie.fromJson(Map<String, dynamic>.from(model)))
          .toList();

      moviesState.setStarterDeckMovies(movies);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Starter deck background load failed: $error');
      debugPrint('$stackTrace');
      moviesState.markStarterDeckRequestFinished();
      return false;
    }
  }

  void selectNavigationTab(int index) {
    if (index < 0 || index >= _visitedTabs.length) {
      return;
    }

    if (index == selectedNavigationIndex) {
      _handleActiveTabTap(index);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      selectedNavigationIndex = index;
      _visitedTabs[index] = true;
    });
    widget.onNavigationIndexChanged?.call(index);
  }

  void _handleActiveTabTap(int index) {
    switch (index) {
      case 0:
        unawaited(_discoverKey.currentState?.handleActiveTabTap());
        return;
      case 1:
        unawaited(_searchKey.currentState?.handleActiveTabTap());
        return;
      case 2:
        unawaited(_myMoviesKey.currentState?.handleActiveTabTap());
        return;
      case 3:
        unawaited(_listsKey.currentState?.handleActiveTabTap());
        return;
      case 4:
        unawaited(_settingsKey.currentState?.handleActiveTabTap());
        return;
    }
  }

  Future<void> _startRatingFromLibrary() async {
    final userState = Provider.of<UserState>(context, listen: false);
    await userState.setOnboardingStage(OnboardingStage.rating);
  }

  Widget _buildRootTab(int index) {
    if (!_visitedTabs[index]) {
      return SizedBox.shrink(key: ValueKey('unvisited-root-tab-$index'));
    }

    return switch (index) {
      0 => DiscoverPage(
          key: _discoverKey,
          isOffline: _refreshError != null,
          isRefreshing: _refreshInFlight,
          onRetry: _refreshRemoteData,
          onOpenLists: () => selectNavigationTab(3),
        ),
      1 => SearchPage(
          key: _searchKey,
          isActive: selectedNavigationIndex == 1,
          handlesBackNavigation: false,
        ),
      2 => MovieList(
          key: _myMoviesKey,
          onOpenDiscover: () => selectNavigationTab(0),
          onStartRating: () => unawaited(_startRatingFromLibrary()),
          isRefreshing: _refreshInFlight,
          refreshError: _refreshError,
          onRetry: _refreshRemoteData,
        ),
      3 => MoviesListsPage(
          key: _listsKey,
          initialPageIndex: 0,
        ),
      4 => Settings(key: _settingsKey),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);
    final loaderState = Provider.of<LoaderState>(context);

    if (!initialDataLoaded) {
      return _buildInitialLoadingState();
    }

    if (loaderState.isLoaderVisible && moviesState.userMovies.isNotEmpty) {
      loaderState.setIsLoaderVisible(false);
    }

    final shouldShowOnboarding =
        userState.launchDestination == LaunchDestination.rateMovies ||
            _retainOnboardingDuringExit;

    if (shouldShowOnboarding && AdManager.bannerVisible) {
      Future.microtask(AdManager.hideBanner);
    }

    if (shouldShowOnboarding) {
      return OnboardingWizardPage(
        onExitStarted: () {
          if (!mounted || _retainOnboardingDuringExit) {
            return;
          }
          setState(() {
            _retainOnboardingDuringExit = true;
          });
        },
        onExitCompleted: () {
          if (!mounted || !_retainOnboardingDuringExit) {
            return;
          }
          setState(() {
            _retainOnboardingDuringExit = false;
          });
        },
        onFinished: () {
          if (!mounted) {
            return;
          }

          setState(() {
            selectedNavigationIndex = 0;
            _visitedTabs[0] = true;
            _retainOnboardingDuringExit = false;
          });
          widget.onNavigationIndexChanged?.call(0);
        },
      );
    }

    final showAds = selectedNavigationIndex != 0 &&
        AdManager.bannerVisible &&
        AdManager.bannersReady;

    final myMoviesWidget = MovieDiaryRootNavigationShell(
      selectedIndex: selectedNavigationIndex,
      tabs: List<Widget>.generate(5, _buildRootTab),
      onTabSelected: selectNavigationTab,
      resizeToAvoidBottomInset: selectedNavigationIndex == 1,
      appBar: showAds
          ? AppBar(
              title:
                  Center(child: AdManager.getBannerWidget(AdManager.bannerAd)),
              elevation: 0.7,
            )
          : PreferredSize(preferredSize: const Size(0, 0), child: Container()),
    );
    return myMoviesWidget;
  }

  Widget _buildInitialLoadingState() {
    return const Scaffold(
      backgroundColor: Md3Colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(),
              Image(
                image: AssetImage('Assets/mdIcon_V_with_effect.png'),
                width: 72,
                height: 72,
              ),
              SizedBox(height: 24),
              Text(
                'MovieDiary',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Md3Colors.text,
                  fontSize: 30,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Loading your library',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Md3Colors.primary,
                  fontSize: 17,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your saved movies will appear first. Fresh details load in the background.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Md3Colors.primary,
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
