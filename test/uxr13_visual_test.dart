import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final density in <double>[1, 2, 3]) {
    testWidgets(
      'UXR13 shared loading and fallback catalog at ${density}x density',
      (tester) async {
        tester.view.devicePixelRatio = density;
        tester.view.physicalSize = Size(390 * density, 760 * density);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: const TextScaler.linear(2),
                ),
                child: child!,
              );
            },
            home: Scaffold(
              backgroundColor: Md3Colors.background,
              body: RepaintBoundary(
                key: const Key('uxr13-visual-catalog'),
                child: ColoredBox(
                  color: Md3Colors.background,
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Loading and image fallbacks',
                              style: TextStyle(
                                color: Md3Colors.text,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Md3MoviePoster(
                                  movie: _movie('compact-fallback'),
                                  width: 72,
                                  height: 108,
                                  hydrateMissingPoster: false,
                                ),
                                const SizedBox(width: 12),
                                Md3MoviePoster(
                                  movie: _movie('large-fallback'),
                                  width: 104,
                                  height: 156,
                                  hydrateMissingPoster: false,
                                ),
                                const SizedBox(width: 12),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Md3ProviderLogo(
                                      providerName: 'Netflix',
                                      logoPath: null,
                                    ),
                                    SizedBox(height: 12),
                                    Md3SkeletonBox(
                                      width: 40,
                                      height: 40,
                                      radius: 10,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Md3ListSkeletonCard(rows: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const Key('uxr13-visual-catalog')),
          matchesGoldenFile(
            'goldens/uxr13-components-${density.toInt()}x.png',
          ),
        );
      },
    );
  }
}

Movie _movie(String id) {
  return Movie(
    id: id,
    title: id == 'large-fallback' ? 'Arrival' : 'MovieDiary',
    overview: '',
    tagline: null,
    posterPath: '',
    duration: 116,
    rating: 90,
    allVotes: 10,
    likedVotes: 9,
    dislikedVotes: 1,
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
