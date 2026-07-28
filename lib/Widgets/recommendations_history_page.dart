import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Enums/recommendation_discovery_level.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Variables/variables.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:provider/provider.dart';
import '../Helpers/rating_helper.dart';
import 'movie_list_item.dart';
import 'Shared/md3_ui.dart';
import 'Shared/m_movies_animated_list.dart';

class RecommendationsHistoryPage extends StatefulWidget {
  const RecommendationsHistoryPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return RecommendationsHistoryPageState();
  }
}

class RecommendationsHistoryPageState
    extends State<RecommendationsHistoryPage> {
  final serviceAgent = ServiceAgent();
  GlobalKey? globalKey;
  UserState? userState;
  List<Movie> history = <Movie>[];
  bool isLoading = false;
  bool _started = false;
  String? errorMessage;

  static const _historyTimeout = Duration(seconds: 12);
  static const _minimumSkeletonVisibility = Duration(milliseconds: 500);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userState ??= Provider.of<UserState>(context, listen: false);
    if (_started || userState!.userId == null || userState!.userId!.isEmpty) {
      return;
    }

    _started = true;
    Future.microtask(getHistory);
  }

  Future<void> getHistory() async {
    if (isLoading) {
      return;
    }

    final wasInitiallyEmpty = history.isEmpty;
    final stopwatch = Stopwatch()..start();
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final moviesResponse = await serviceAgent
          .getUserRecommendationsHistory(userState!.userId!)
          .timeout(_historyTimeout);

      if (moviesResponse.statusCode < 200 || moviesResponse.statusCode >= 300) {
        throw StateError(
          'History request failed with ${moviesResponse.statusCode}.',
        );
      }

      final Iterable iterableMovies = json.decode(moviesResponse.body);
      final movies =
          iterableMovies.map<Movie>((model) => Movie.fromJson(model)).toList();

      await _holdInitialSkeleton(stopwatch, wasInitiallyEmpty);
      if (!mounted) {
        return;
      }

      RatingHelper.refreshMoviesRating(movies, context);
      setState(() {
        history = movies;
        isLoading = false;
      });
    } catch (error) {
      debugPrint('Recommendation history failed: $error');
      await _holdInitialSkeleton(stopwatch, wasInitiallyEmpty);
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage =
            'MovieDiary could not load recommendation history. Try again.';
      });
    }
  }

  Future<void> _holdInitialSkeleton(
    Stopwatch stopwatch,
    bool wasInitiallyEmpty,
  ) async {
    if (!wasInitiallyEmpty) {
      return;
    }
    final remaining = _minimumSkeletonVisibility - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  @override
  Widget build(BuildContext context) {
    userState ??= Provider.of<UserState>(context, listen: false);

    if (ModalRoute.of(context)!.isCurrent &&
        (globalKey == null || globalKey != MyGlobals.activeKey)) {
      globalKey = GlobalKey();

      MyGlobals.activeKey = globalKey;
    }

    Widget buildItem(Movie movie, Animation<double> animation,
        {bool isPremium = false, required BuildContext context}) {
      final historyMetadata = _historyMetadata(movie);

      return SizeTransition(
          key: ObjectKey(movie),
          sizeFactor: animation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (historyMetadata != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Text(
                    historyMetadata,
                    style: const TextStyle(
                      color: Md3Colors.muted,
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              MovieListItem(movie: movie),
            ],
          ));
    }

    const headingField = Text("Recommendations History");

    final moviesListWidget = Container(
        key: globalKey,
        color: Md3Colors.background,
        padding: const EdgeInsets.only(top: 8),
        child: MMoviesAnimatedList(
          buildItemFunction: buildItem,
          isPremium: userState!.isPremium,
          movies: history,
          padding: const EdgeInsets.only(bottom: 16),
        ));

    final emptyHistoryWidget = Md3Page(
      padding: EdgeInsets.fromLTRB(
        Md3Layout.pageHorizontalInset(context),
        18,
        Md3Layout.pageHorizontalInset(context),
        24,
      ),
      child: Md3Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No recommendation history yet',
              style: TextStyle(
                color: Md3Colors.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start Discovery from Discover to save recommendation batches here.',
              style: TextStyle(
                color: Md3Colors.muted,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Md3PrimaryButton(
              text: 'Back to Discovery',
              icon: Icons.arrow_back_rounded,
              tonal: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );

    final loaderWidget = Semantics(
      liveRegion: true,
      label: 'Loading recommendation history',
      child: const Padding(
        padding: EdgeInsets.fromLTRB(0, 10, 0, 24),
        child: Md3ListSkeletonCard(rows: 4),
      ),
    );

    final errorHistoryWidget = Md3Page(
      padding: EdgeInsets.fromLTRB(
        Md3Layout.pageHorizontalInset(context),
        18,
        Md3Layout.pageHorizontalInset(context),
        24,
      ),
      child: Md3Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'History unavailable',
              style: TextStyle(
                color: Md3Colors.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'MovieDiary could not load this history.',
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 16,
                height: 23 / 16,
              ),
            ),
            const SizedBox(height: 16),
            Md3PrimaryButton(
              text: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: getHistory,
            ),
          ],
        ),
      ),
    );

    MyGlobals.personalListsKey = GlobalKey<AnimatedListState>();

    final cachedHistoryWidget = Column(
      children: [
        if (isLoading)
          const _HistoryStatusBanner(
            message: 'Refreshing recommendation history',
            isLoading: true,
          )
        else if (errorMessage != null)
          _HistoryStatusBanner(
            message:
                'Showing saved history. MovieDiary could not refresh it right now.',
            onRetry: getHistory,
          ),
        Expanded(child: moviesListWidget),
      ],
    );

    return Scaffold(
        backgroundColor: Md3Colors.background,
        appBar: AdManager.bannerVisible && AdManager.bannersReady
            ? AppBar(
                title: Center(
                  child: AdManager.getBannerWidget(
                      AdManager.recommendationsHistoryBannerAd),
                ),
                elevation: 0.7,
                automaticallyImplyLeading: false)
            : PreferredSize(
                preferredSize: const Size(0, 0), child: Container()),
        body: Scaffold(
            backgroundColor: Md3Colors.background,
            appBar: AppBar(
              title: headingField,
              backgroundColor: Md3Colors.background,
              foregroundColor: Md3Colors.text,
              elevation: 0,
            ),
            body: isLoading && history.isEmpty
                ? loaderWidget
                : errorMessage != null && history.isEmpty
                    ? errorHistoryWidget
                    : history.isEmpty
                        ? emptyHistoryWidget
                        : cachedHistoryWidget));
  }

  String? _historyMetadata(Movie movie) {
    final generatedAt = movie.recommendationGeneratedAt ?? movie.updated;
    final level = movie.recommendationDiscoveryLevel;
    if (generatedAt == null && level == null) {
      return null;
    }

    final parts = <String>[
      movie.movieType == MovieType.tv ? 'TV deck' : 'Movie deck',
      if (level != null)
        switch (level) {
          RecommendationDiscoveryLevel.safe => 'Familiar',
          RecommendationDiscoveryLevel.balanced => 'Balanced',
          RecommendationDiscoveryLevel.adventurous => 'Adventurous',
        },
      if (generatedAt != null)
        DateFormat('MMM d, yyyy').format(generatedAt.toLocal()),
    ];

    return parts.join('  •  ');
  }
}

class _HistoryStatusBanner extends StatelessWidget {
  final String message;
  final bool isLoading;
  final VoidCallback? onRetry;

  const _HistoryStatusBanner({
    required this.message,
    this.isLoading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 2),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: Md3Colors.primarySoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Md3Colors.primary.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isLoading ? Icons.sync_rounded : Icons.cloud_off_outlined,
              color: Md3Colors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Md3Colors.text,
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Md3Colors.primary,
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: onRetry,
                child: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
