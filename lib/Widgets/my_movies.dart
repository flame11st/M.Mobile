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
import 'movies_bottom_navigation_bar.dart';
import 'movie_list.dart';
import 'discover_page.dart';
import 'onboarding_wizard_page.dart';
import 'Providers/loader_state.dart';
import 'Providers/movies_state.dart';
import 'Providers/user_state.dart';
import 'Shared/md3_ui.dart';

class MyMovies extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyMoviesState();
  }
}

class MyMoviesState extends State<MyMovies> {
  final serviceAgent = ServiceAgent();
  static const _initialDataLoadTimeout = Duration(seconds: 12);
  int selectedNavigationIndex = 0;
  bool initialDataLoaded = false;
  String? _initialDataLoadError;

  bool _isSuccessfulJsonResponse(String body, int statusCode) {
    return statusCode >= 200 && statusCode < 300 && body.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (mounted) {
        setUserData();
      }
    });
  }

  Future<void> setUserMovies() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final loaderState = Provider.of<LoaderState>(context, listen: false);

    if (userState.isIncognitoMode) {
      if (loaderState.isLoaderVisible) {
        loaderState.setIsLoaderVisible(false);
      }

      await moviesState.setInitialData();

      unawaited(_refreshIncognitoUserMoviesInBackground(
        moviesState,
        userState,
      ));

      return;
    }

    final moviesResponse = await serviceAgent.getUserMovies(userState.userId!);
    final responseBody = moviesResponse.body.trim();

    if (!_isSuccessfulJsonResponse(responseBody, moviesResponse.statusCode)) {
      debugPrint('User movies load skipped: ${moviesResponse.statusCode}');
      moviesState.setUserMovies([]);
      if (loaderState.isLoaderVisible) {
        loaderState.setIsLoaderVisible(false);
      }
      return;
    }

    Iterable iterableMovies;
    try {
      final decodedBody = json.decode(responseBody);
      if (decodedBody is! Iterable) {
        debugPrint('User movies response was not a list.');
        moviesState.setUserMovies([]);
        if (loaderState.isLoaderVisible) {
          loaderState.setIsLoaderVisible(false);
        }
        return;
      }

      iterableMovies = decodedBody;
    } on FormatException catch (error) {
      debugPrint('User movies response was not valid JSON: $error');
      moviesState.setUserMovies([]);
      if (loaderState.isLoaderVisible) {
        loaderState.setIsLoaderVisible(false);
      }
      return;
    }

    debugPrint('Movies loaded');

    if (iterableMovies.isNotEmpty) {
      List<Movie> movies = iterableMovies.map((model) {
        return Movie.fromJson(model);
      }).toList();

      moviesState.setUserMovies(movies);
    } else {
      moviesState.setUserMovies([]);
    }

    if (loaderState.isLoaderVisible) {
      loaderState.setIsLoaderVisible(false);
    }
  }

  Future<void> _refreshIncognitoUserMoviesInBackground(
    MoviesState moviesState,
    UserState userState,
  ) async {
    try {
      final moviesResponse =
          await serviceAgent.getUserMovies(userState.userId!);
      final responseBody = moviesResponse.body.trim();
      if (_isSuccessfulJsonResponse(
        responseBody,
        moviesResponse.statusCode,
      )) {
        try {
          final decodedBody = json.decode(responseBody);
          if (decodedBody is Iterable && decodedBody.isNotEmpty) {
            final movies =
                decodedBody.map((model) => Movie.fromJson(model)).toList();
            await moviesState.setUserMovies(movies);
            return;
          }
        } on FormatException catch (error) {
          debugPrint('Anonymous user movies were not valid JSON: $error');
        }
      }

      await setIncognitoUserMovies(moviesState);
      _syncCachedAnonymousRatings(moviesState, userState);
    } catch (error, stackTrace) {
      debugPrint('Incognito movies background refresh failed: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> setIncognitoUserMovies(MoviesState moviesState) async {
    final moviesIds = moviesState.cachedUserMovies.map((e) => e.id).toList();

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

  Future<void> setMoviesLists() async {
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
      if (userState.isIncognitoMode) {
        moviesState.setInitialMoviesListsIncognito([]);
      } else {
        moviesState.setInitialMoviesLists([]);
      }

      return;
    }

    Iterable iterableMoviesLists;
    try {
      final decodedBody = json.decode(responseBody);
      if (decodedBody is! Iterable) {
        debugPrint('Movies lists response was not a list.');
        if (userState.isIncognitoMode) {
          moviesState.setInitialMoviesListsIncognito([]);
        } else {
          moviesState.setInitialMoviesLists([]);
        }

        return;
      }

      iterableMoviesLists = decodedBody;
    } on FormatException catch (error) {
      debugPrint('Movies lists response was not valid JSON: $error');
      if (userState.isIncognitoMode) {
        moviesState.setInitialMoviesListsIncognito([]);
      } else {
        moviesState.setInitialMoviesLists([]);
      }

      return;
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
    final loaderState = Provider.of<LoaderState>(context, listen: false);

    if (mounted) {
      setState(() {
        initialDataLoaded = false;
        _initialDataLoadError = null;
      });
    }

    try {
      await setUserInfo();
      unawaited(_loadStarterDeckInBackground());
      unawaited(_loadMoviesListsInBackground());
      await setUserMovies().timeout(_initialDataLoadTimeout);
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('Initial user data load timed out: $error');
      debugPrint('$stackTrace');
      _initialDataLoadError =
          'MovieDiary could not finish loading your library. You can retry, or start rating while we reconnect.';
    } catch (error, stackTrace) {
      debugPrint('Initial user data load failed: $error');
      debugPrint('$stackTrace');
      _initialDataLoadError =
          'MovieDiary could not load your library. Your saved movies are still safe; try again when the API is reachable.';
    } finally {
      if (loaderState.isLoaderVisible) {
        loaderState.setIsLoaderVisible(false);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      initialDataLoaded = _initialDataLoadError == null;
    });
  }

  Future<void> _loadMoviesListsInBackground() async {
    try {
      await setMoviesLists().timeout(_initialDataLoadTimeout);
    } catch (error, stackTrace) {
      debugPrint('Movies lists background load failed: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _loadStarterDeckInBackground() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    if (moviesState.starterDeckMovies.isNotEmpty) {
      return;
    }

    try {
      final response = await serviceAgent
          .getStarterDeck(perBucket: 20)
          .timeout(_initialDataLoadTimeout);
      final responseBody = response.body.trim();

      if (!_isSuccessfulJsonResponse(responseBody, response.statusCode)) {
        debugPrint('Starter deck load skipped: ${response.statusCode}');
        moviesState.setStarterDeckMovies([]);
        return;
      }

      final decodedBody = json.decode(responseBody);
      if (decodedBody is! Iterable) {
        debugPrint('Starter deck response was not a list.');
        moviesState.setStarterDeckMovies([]);
        return;
      }

      final movies = decodedBody
          .map((model) => Movie.fromJson(Map<String, dynamic>.from(model)))
          .toList();

      moviesState.setStarterDeckMovies(movies);
    } catch (error, stackTrace) {
      debugPrint('Starter deck background load failed: $error');
      debugPrint('$stackTrace');
      moviesState.setStarterDeckMovies([]);
    }
  }

  void selectNavigationTab(int index) {
    setState(() {
      selectedNavigationIndex = index;
    });
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

    final ratedMoviesCount = moviesState.userMovies
        .where((movie) => MovieRate.isViewed(movie.movieRate))
        .length;
    final shouldShowOnboarding = !userState.onboardingCompleted &&
        !userState.onboardingSkipped &&
        ratedMoviesCount < 10;

    if (shouldShowOnboarding && AdManager.bannerVisible) {
      Future.microtask(AdManager.hideBanner);
    }

    if (shouldShowOnboarding) {
      return OnboardingWizardPage(
        onFinished: () {
          if (!mounted) {
            return;
          }

          setState(() {
            selectedNavigationIndex = 0;
          });
        },
      );
    }

    final showAds = selectedNavigationIndex != 0 &&
        AdManager.bannerVisible &&
        AdManager.bannersReady;

    final myMoviesWidget = Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: showAds
          ? AppBar(
              title:
                  Center(child: AdManager.getBannerWidget(AdManager.bannerAd)),
              elevation: 0.7,
            )
          : PreferredSize(preferredSize: const Size(0, 0), child: Container()),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          selectedNavigationIndex == 0 ? const DiscoverPage() : MovieList(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MoviesBottomNavigationBar(
              selectedIndex: selectedNavigationIndex,
              onTabSelected: selectNavigationTab,
            ),
          ),
        ],
      ),
    );
    return myMoviesWidget;
  }

  Widget _buildInitialLoadingState() {
    final hasError = _initialDataLoadError != null;

    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: const Center(
                  child: Image(
                    image: AssetImage('Assets/mdIcon_V_with_effect.png'),
                    width: 54,
                  ),
                ),
              ),
              Text(
                hasError ? 'Library did not load' : 'Loading your library',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff1f2937),
                  fontSize: 32,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hasError
                    ? _initialDataLoadError!
                    : 'Bringing in your watchlist, viewed movies, and lists.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff6b7280),
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              if (hasError) ...[
                Md3PrimaryButton(
                  text: 'Try Again',
                  icon: Icons.refresh_rounded,
                  onPressed: setUserData,
                ),
                const SizedBox(height: 12),
                Md3PrimaryButton(
                  text: 'Start Rating',
                  icon: Icons.movie_filter_rounded,
                  tonal: true,
                  onPressed: () {
                    setState(() {
                      initialDataLoaded = true;
                      _initialDataLoadError = null;
                    });
                  },
                ),
              ] else
                const Md3ListSkeletonCard(
                  rows: 2,
                  showTrailing: false,
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
