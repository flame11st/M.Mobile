import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'null and malformed poster URLs use stable branded fallbacks without network work',
      (tester) async {
    final parsedMovie = Movie.fromJson(_movieJson(posterPath: null));
    expect(parsedMovie.posterPath, isEmpty);

    await tester.pumpWidget(
      _testApp(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Md3MoviePoster(
              movie: parsedMovie,
              width: 72,
              height: 108,
              hydrateMissingPoster: false,
            ),
            const SizedBox(width: 12),
            Md3MoviePoster(
              movie: _movie(
                id: 'malformed-poster',
                posterPath: 'not a valid poster path',
              ),
              width: 122,
              height: 184,
              hydrateMissingPoster: false,
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(const Key('md3-poster-fallback')), findsNWidgets(2));
    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    expect(find.text('MD'), findsOneWidget);
    expect(find.text('No poster'), findsOneWidget);
    expect(
      tester.getSize(find.byType(Md3MoviePoster).first),
      const Size(72, 108),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'row skeleton matches final geometry and becomes static for reduced motion',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        const Md3ListSkeletonCard(rows: 2),
        disableAnimations: true,
        textScale: 2,
      ),
    );

    expect(find.byType(Md3ListSkeletonCard), findsOneWidget);
    expect(find.byType(Md3SkeletonBox), findsNWidgets(12));
    final firstBox = tester.widget<Md3SkeletonBox>(
      find.byType(Md3SkeletonBox).first,
    );
    expect(firstBox.width, 72);
    expect(firstBox.height, 108);
    final renderedBox = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(Md3SkeletonBox).first,
            matching: find.byType(Container),
          )
          .first,
    );
    expect((renderedBox.decoration! as BoxDecoration).gradient, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('malformed network URL skips image resolution immediately',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        const Md3ProgressiveNetworkImage(
          imageUrl: 'malformed url',
          width: 72,
          height: 108,
          borderRadius: 12,
          placeholder: ColoredBox(color: Colors.yellow),
          fallback: ColoredBox(
            key: Key('direct-invalid-fallback'),
            color: Colors.blue,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('direct-invalid-fallback')), findsOneWidget);
    expect(
        find.byKey(const Key('md3-progressive-image-loading')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'slow images keep exact geometry and cached success skips fallback',
      (tester) async {
    const slowProvider = _PendingImageProvider('slow-success');

    await tester.pumpWidget(
      _testApp(
        const Md3ProgressiveNetworkImage(
          imageUrl: null,
          imageProvider: slowProvider,
          width: 72,
          height: 108,
          borderRadius: 12,
          loadingTimeout: Duration(milliseconds: 300),
          placeholder: ColoredBox(
            key: Key('slow-placeholder'),
            color: Colors.yellow,
          ),
          fallback: ColoredBox(
            key: Key('slow-fallback'),
            color: Colors.red,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('slow-placeholder')), findsOneWidget);
    expect(
      tester.getSize(find.byType(Md3ProgressiveNetworkImage)),
      const Size(72, 108),
    );
    await tester.pump(const Duration(milliseconds: 301));
    expect(find.byKey(const Key('slow-placeholder')), findsNothing);
    expect(find.byKey(const Key('slow-fallback')), findsOneWidget);

    const cachedProvider = AssetImage('Assets/mdIcon_V_new_white.png');
    await tester.pumpWidget(
      _testApp(
        Builder(
          key: const Key('precache-context'),
          builder: (context) => const SizedBox.shrink(),
        ),
      ),
    );
    final precacheContext =
        tester.element(find.byKey(const Key('precache-context')));
    await tester.runAsync(
      () => precacheImage(cachedProvider, precacheContext),
    );

    await tester.pumpWidget(
      _testApp(
        const Md3ProgressiveNetworkImage(
          imageUrl: null,
          imageProvider: cachedProvider,
          width: 72,
          height: 108,
          borderRadius: 12,
          placeholder: ColoredBox(
            key: Key('cached-placeholder'),
            color: Colors.yellow,
          ),
          fallback: ColoredBox(
            key: Key('cached-fallback'),
            color: Colors.red,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cached-placeholder')), findsNothing);
    expect(find.byKey(const Key('cached-fallback')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('404 and image decode failures become deliberate fallbacks',
      (tester) async {
    for (final provider in <ImageProvider<Object>>[
      const _FailingImageProvider('404'),
      _DelayedMemoryImage(
        Uint8List.fromList(const [0, 1, 2, 3]),
        cacheKey: 'decode-failure',
      ),
    ]) {
      await tester.pumpWidget(
        _testApp(
          Md3ProgressiveNetworkImage(
            imageUrl: null,
            imageProvider: provider,
            width: 72,
            height: 108,
            borderRadius: 12,
            placeholder: const ColoredBox(color: Colors.yellow),
            fallback: const ColoredBox(
              key: Key('failed-image-fallback'),
              color: Colors.blue,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('failed-image-fallback')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('provider fallback reserves 40px and keeps provider identity',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Md3ProviderLogo(
              providerName: 'Netflix',
              logoPath: null,
            ),
            SizedBox(width: 8),
            Text('Netflix'),
          ],
        ),
      ),
    );

    expect(find.byKey(const Key('md3-provider-fallback')), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
    expect(
      tester.getSize(find.byType(Md3ProviderLogo)),
      const Size(40, 40),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'missing poster metadata hydrates once per movie and caches failure',
      (tester) async {
    var hydrationCalls = 0;
    Future<String?> loader(String movieId) async {
      hydrationCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return null;
    }

    final movie = _movie(id: 'legacy-history-cache', posterPath: '');
    await tester.pumpWidget(
      _testApp(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Md3MoviePoster(
              movie: movie,
              width: 72,
              height: 108,
              metadataLoader: loader,
            ),
            Md3MoviePoster(
              movie: movie,
              width: 72,
              height: 108,
              metadataLoader: loader,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(hydrationCalls, 1);
    expect(find.byKey(const Key('md3-poster-fallback')), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('one hundred fallback posters scroll without overflow',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 568));

    await tester.pumpWidget(
      _testApp(
        ListView.builder(
          itemCount: 100,
          itemExtent: 120,
          itemBuilder: (context, index) => Row(
            children: [
              Md3MoviePoster(
                key: ValueKey(index),
                movie: _movie(id: 'movie-$index', posterPath: ''),
                width: 72,
                height: 108,
                hydrateMissingPoster: false,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Movie $index')),
            ],
          ),
        ),
        textScale: 2,
      ),
    );

    await tester.fling(find.byType(ListView), const Offset(0, -5000), 8000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp(
  Widget child, {
  bool disableAnimations = false,
  double textScale = 1,
}) {
  return MaterialApp(
    builder: (context, appChild) {
      final mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScale),
        ),
        child: appChild!,
      );
    },
    home: Scaffold(
      backgroundColor: Md3Colors.background,
      body: Center(child: child),
    ),
  );
}

Movie _movie({
  required String id,
  required String posterPath,
}) {
  return Movie(
    id: id,
    title: 'Test Movie',
    overview: '',
    tagline: null,
    posterPath: posterPath,
    duration: 100,
    rating: 80,
    allVotes: 10,
    likedVotes: 8,
    dislikedVotes: 2,
    countries: 'US',
    actors: const [],
    directors: const [],
    genres: const ['Drama'],
    movieRate: MovieRate.notRated,
    movieType: MovieType.movie,
    releaseDate: DateTime(2020),
    averageTimeOfEpisode: 0,
    inProduction: false,
    seasonsCount: 0,
    imdbRate: 8,
    imdbVotes: 100,
  );
}

Map<String, dynamic> _movieJson({required Object? posterPath}) {
  return {
    'id': 'parsed-movie',
    'title': 'Parsed Movie',
    'tagline': null,
    'overview': '',
    'posterPath': posterPath,
    'genres': <String>['Drama'],
    'releaseDate': '2020-01-01T00:00:00.000Z',
    'duration': 100,
    'likedVotes': 8,
    'unlikedVotes': 2,
    'movieRate': MovieRate.notRated,
    'movieType': MovieType.movie.index,
    'countries': 'US',
    'actors': <String>[],
    'directors': <String>[],
    'seasonsCount': 0,
    'averageTimeOfEpisode': 0,
    'inProduction': false,
    'imdbRate': 8,
    'imdbVotes': 100,
  };
}

class _DelayedMemoryImage extends ImageProvider<_DelayedMemoryImage> {
  final Uint8List bytes;
  final String cacheKey;

  const _DelayedMemoryImage(
    this.bytes, {
    required this.cacheKey,
  });

  @override
  Future<_DelayedMemoryImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_DelayedMemoryImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _DelayedMemoryImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(decode),
      scale: 1,
      debugLabel: cacheKey,
    );
  }

  Future<ui.Codec> _loadAsync(ImageDecoderCallback decode) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    return other is _DelayedMemoryImage && other.cacheKey == cacheKey;
  }

  @override
  int get hashCode => cacheKey.hashCode;
}

class _FailingImageProvider extends ImageProvider<_FailingImageProvider> {
  final String cacheKey;

  const _FailingImageProvider(this.cacheKey);

  @override
  Future<_FailingImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_FailingImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _FailingImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: Future<ui.Codec>.error(StateError('404 image response')),
      scale: 1,
      debugLabel: cacheKey,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _FailingImageProvider && other.cacheKey == cacheKey;
  }

  @override
  int get hashCode => cacheKey.hashCode;
}

class _PendingImageProvider extends ImageProvider<_PendingImageProvider> {
  final String cacheKey;

  const _PendingImageProvider(this.cacheKey);

  @override
  Future<_PendingImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_PendingImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _PendingImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: Completer<ui.Codec>().future,
      scale: 1,
      debugLabel: cacheKey,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _PendingImageProvider && other.cacheKey == cacheKey;
  }

  @override
  int get hashCode => cacheKey.hashCode;
}
