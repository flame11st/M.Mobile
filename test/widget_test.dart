import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';

void main() {
  testWidgets('poster without an image path uses a stable graceful fallback',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Md3MoviePoster(
              movie: _movie(posterPath: ''),
              width: 64,
              height: 96,
            ),
          ),
        ),
      ),
    );

    expect(find.text('No poster'), findsOneWidget);
    expect(tester.getSize(find.byType(Md3MoviePoster)), const Size(64, 96));
    expect(tester.takeException(), isNull);
  });

  testWidgets('list skeleton preserves one card per future movie row',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Md3ListSkeletonCard(rows: 3),
          ),
        ),
      ),
    );

    expect(find.byType(Md3Card), findsNWidgets(3));
    expect(find.byType(Md3SkeletonBox), findsNWidgets(15));
    expect(tester.takeException(), isNull);
  });
}

Movie _movie({required String posterPath}) {
  return Movie(
    id: 'test-movie',
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
