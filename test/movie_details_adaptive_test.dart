import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movie_watch_provider_group.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/movie_list_item_expanded.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('status surface is content-driven without shrink-to-fit copy',
      (tester) async {
    final movie = _movie();
    final states = await _testStates(movie);
    addTearDown(states.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpDetails(
      tester,
      states,
      movie: movie,
      size: const Size(390, 844),
      providers: _group(streamCount: 1),
    );

    final statusCard = find
        .ancestor(
          of: find.text('Set your status'),
          matching: find.byType(Md3Card),
        )
        .first;

    expect(tester.getSize(statusCard).height, lessThan(270));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == 220,
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.text('Set your status'),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hero keeps full title and earns space with useful metadata',
      (tester) async {
    const title =
        'A Very Long Television Title That Must Remain Fully Readable';
    final movie = _movie(
      title: title,
      movieType: MovieType.tv,
      seasonsCount: 4,
      duration: 0,
      tagline: null,
    );
    final states = await _testStates(movie);
    addTearDown(states.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpDetails(
      tester,
      states,
      movie: movie,
      size: const Size(390, 844),
      providers: _group(streamCount: 1),
    );

    final heroCard = find.byKey(const Key('movie-details-hero'));
    final heroTitle = tester.widget<Text>(
      find.descendant(of: heroCard, matching: find.text(title)),
    );

    expect(heroTitle.maxLines, isNull);
    expect(
      find.descendant(of: heroCard, matching: find.text('Science Fiction')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: heroCard, matching: find.text('MovieDiary 91%')),
      findsOneWidget,
    );
    expect(find.textContaining('4 seasons  /  Ended'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider groups use headings above a two-column phone grid',
      (tester) async {
    final movie = _movie();
    final states = await _testStates(movie);
    addTearDown(states.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpDetails(
      tester,
      states,
      movie: movie,
      size: const Size(390, 844),
      providers: _group(streamCount: 4),
    );
    await tester.scrollUntilVisible(find.text('Where to Watch'), 300);
    await tester.pump();

    final heading = find.byKey(const Key('provider-group-Stream'));
    final first = find.byKey(const Key('provider-tile-1'));
    final second = find.byKey(const Key('provider-tile-2'));

    expect(
        tester.getTopLeft(heading).dy, lessThan(tester.getTopLeft(first).dy));
    expect(
        tester.getTopLeft(first).dy, closeTo(tester.getTopLeft(second).dy, 1));
    expect(tester.getSize(first).width, greaterThan(140));
    expect(tester.getSize(first).width, lessThan(170));
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider disclosure preserves top four and expands all groups',
      (tester) async {
    final movie = _movie();
    final states = await _testStates(movie);
    addTearDown(states.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpDetails(
      tester,
      states,
      movie: movie,
      size: const Size(430, 930),
      providers: _group(streamCount: 5, rentCount: 3, buyCount: 2),
    );
    await tester.scrollUntilVisible(find.text('Where to Watch'), 300);
    await tester.pump();

    expect(find.byKey(const Key('provider-tile-1')), findsOneWidget);
    expect(find.byKey(const Key('provider-tile-4')), findsOneWidget);
    expect(find.byKey(const Key('provider-tile-5')), findsNothing);
    expect(find.text('Show all 10'), findsOneWidget);

    await tester.tap(find.text('Show all 10'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('provider-tile-10')), findsOneWidget);
    expect(find.byKey(const Key('provider-group-Rent')), findsOneWidget);
    expect(find.byKey(const Key('provider-group-Buy')), findsOneWidget);

    await tester.ensureVisible(find.text('Show less'));
    await tester.pump();
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('provider-tile-5')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long provider names fall back to a readable full-width tile',
      (tester) async {
    final movie = _movie();
    final states = await _testStates(movie);
    addTearDown(states.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpDetails(
      tester,
      states,
      movie: movie,
      size: const Size(390, 844),
      textScale: 1.3,
      providers: MovieWatchProviderGroup(
        movieId: movie.id,
        country: 'US',
        source: 'TMDb',
        sourceLink: 'https://www.themoviedb.org',
        stream: const [
          MovieWatchProvider(
            providerId: 99,
            providerName: 'An Exceptionally Long Streaming Provider Name',
            displayPriority: 1,
          ),
        ],
        rent: const [],
        buy: const [],
      ),
    );
    await tester.scrollUntilVisible(find.text('Where to Watch'), 300);
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const Key('provider-tile-99'))).width,
      greaterThan(300),
    );
    expect(
      find.text('An Exceptionally Long Streaming Provider Name'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider error remains truthful and retry recovers',
      (tester) async {
    final movie = _movie();
    final states = await _testStates(movie);
    addTearDown(states.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var attempts = 0;

    await _pumpDetails(
      tester,
      states,
      movie: movie,
      size: const Size(390, 844),
      providerLoader: () {
        attempts++;
        if (attempts == 1) {
          return Future<MovieWatchProviderGroup>.error(
            StateError('offline'),
          );
        }
        return Future.value(_group(streamCount: 1));
      },
    );
    await tester.scrollUntilVisible(
      find.text('Streaming availability unavailable'),
      300,
    );
    await tester.pump();

    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('provider-tile-1')), findsOneWidget);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider loading and empty states remain bounded and truthful',
      (tester) async {
    final movie = _movie();
    final states = await _testStates(movie);
    addTearDown(states.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final pending = Completer<MovieWatchProviderGroup>();

    await _pumpDetails(
      tester,
      states,
      movie: movie,
      size: const Size(390, 844),
      providerLoader: () => pending.future,
    );
    await tester.scrollUntilVisible(find.byType(Md3ProviderSkeletonList), 300);
    await tester.pump();
    expect(find.byType(Md3ProviderSkeletonList), findsOneWidget);

    pending.complete(_group());
    await tester.pumpAndSettle();
    expect(find.text('No streaming sources listed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('details matrix has no overflow or clipped meaningful text',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixtures = [
      _movie(
        id: 'long-tagline',
        tagline:
            'A long, atmospheric promise about memory, identity, family, and the difficult choices that follow us across generations.',
      ),
      _movie(id: 'movie-no-tagline', tagline: null),
      _movie(
        id: 'tv-no-tagline',
        movieType: MovieType.tv,
        duration: 0,
        seasonsCount: 7,
        tagline: null,
      ),
      _movie(
        id: 'sparse-long-title',
        title:
            'The Remarkably Long International Title of a Story Without Scores',
        tagline: null,
        overview: '',
        genres: const [
          'Science Fiction',
          'Adventure',
          'Mystery',
          'Drama',
          'Family',
        ],
        allVotes: 0,
        imdbVotes: 0,
      ),
    ];
    const sizes = [Size(320, 568), Size(390, 844), Size(430, 932)];
    const scales = [1.0, 1.3, 2.0];

    for (final movie in fixtures) {
      final states = await _testStates(movie);
      try {
        for (final size in sizes) {
          for (final scale in scales) {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
            await _pumpDetails(
              tester,
              states,
              movie: movie,
              size: size,
              textScale: scale,
              providers: _group(streamCount: 5),
            );
            await tester.pump();

            final heroTitle = tester.widget<Text>(
              find.descendant(
                of: find.byKey(const Key('movie-details-hero')),
                matching: find.text(movie.title),
              ),
            );
            expect(heroTitle.maxLines, isNull);
            expect(
              tester.takeException(),
              isNull,
              reason: '${movie.id} at $size / $scale',
            );
          }
        }
      } finally {
        states.dispose();
      }
    }
  });
}

Future<_TestStates> _testStates(Movie movie) async {
  FlutterSecureStorage.setMockInitialValues({});
  const storage = FlutterSecureStorage();
  final movies = MoviesState(storage: storage);
  await movies.cacheInitialization;
  movies.setInitialUserMovies([movie]);
  return _TestStates(movies);
}

Future<void> _pumpDetails(
  WidgetTester tester,
  _TestStates states, {
  required Movie movie,
  required Size size,
  MovieWatchProviderGroup? providers,
  Future<MovieWatchProviderGroup> Function()? providerLoader,
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    ChangeNotifierProvider<MoviesState>.value(
      value: states.movies,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: MovieListItemExpanded(
          movie: movie,
          imageUrl: '',
          watchProviderLoader: providerLoader ??
              () => Future.value(providers ?? _group(streamCount: 1)),
        ),
      ),
    ),
  );
  await tester.pump();
}

Movie _movie({
  String id = 'details-test',
  String title = 'Adaptive Details Test',
  MovieType movieType = MovieType.movie,
  String? tagline =
      'A deliberately long tagline that should wrap naturally without shrinking.',
  String overview = 'A useful overview for the details screen.',
  List<String> genres = const [
    'Science Fiction',
    'Adventure',
    'Drama',
    'Mystery',
  ],
  int duration = 132,
  int seasonsCount = 0,
  int allVotes = 1200,
  int imdbVotes = 500000,
}) {
  return Movie(
    id: id,
    title: title,
    overview: overview,
    tagline: tagline,
    posterPath: '/test-poster.jpg',
    duration: duration,
    rating: 91,
    allVotes: allVotes,
    likedVotes: 1092,
    dislikedVotes: 108,
    countries: 'United States of America',
    actors: const ['Actor One', 'Actor Two'],
    directors: const ['Director One'],
    genres: genres,
    movieRate: MovieRate.notRated,
    movieType: movieType,
    releaseDate: DateTime(2024),
    averageTimeOfEpisode: movieType == MovieType.tv ? 52 : 0,
    inProduction: false,
    seasonsCount: seasonsCount,
    imdbRate: 8.6,
    imdbVotes: imdbVotes,
  );
}

MovieWatchProviderGroup _group({
  int streamCount = 0,
  int rentCount = 0,
  int buyCount = 0,
}) {
  var nextId = 1;
  List<MovieWatchProvider> providers(int count, String prefix) {
    return List.generate(count, (index) {
      final id = nextId++;
      return MovieWatchProvider(
        providerId: id,
        providerName: '$prefix $id',
        displayPriority: id,
      );
    });
  }

  return MovieWatchProviderGroup(
    movieId: 'details-test',
    country: 'US',
    source: 'TMDb',
    sourceLink: 'https://www.themoviedb.org',
    stream: providers(streamCount, 'Stream'),
    rent: providers(rentCount, 'Rent'),
    buy: providers(buyCount, 'Buy'),
  );
}

class _TestStates {
  final MoviesState movies;

  const _TestStates(this.movies);

  void dispose() => movies.dispose();
}
