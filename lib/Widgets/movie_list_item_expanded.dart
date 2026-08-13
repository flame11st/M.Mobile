import 'package:flutter/material.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movie_watch_provider_group.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/Shared/movie_rate_buttons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MovieListItemExpanded extends StatefulWidget {
  final Movie movie;
  final bool fromSearch;
  final String imageUrl;
  final MoviesList? moviesList;
  final bool shouldRequestReview;
  final Future<MovieWatchProviderGroup> Function()? watchProviderLoader;

  const MovieListItemExpanded(
      {super.key,
      required this.movie,
      this.fromSearch = false,
      required this.imageUrl,
      this.moviesList,
      this.shouldRequestReview = false,
      this.watchProviderLoader});

  @override
  State<StatefulWidget> createState() {
    return MovieListItemExpandedState();
  }
}

class MovieListItemExpandedState extends State<MovieListItemExpanded> {
  late Future<MovieWatchProviderGroup> whereToWatchFuture;
  final serviceAgent = ServiceAgent();
  bool showAllWatchProviders = false;
  static const _providerTimeout = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    whereToWatchFuture = _loadWhereToWatch();
  }

  Future<MovieWatchProviderGroup> _loadWhereToWatch() {
    if (widget.watchProviderLoader != null) {
      return widget.watchProviderLoader!().timeout(_providerTimeout);
    }

    return serviceAgent
        .getWhereToWatchGrouped(widget.movie.id, 'US')
        .timeout(_providerTimeout);
  }

  void _retryWhereToWatch() {
    setState(() {
      showAllWatchProviders = false;
      whereToWatchFuture = _loadWhereToWatch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final matchingMovies = moviesState.userMovies
        .where((element) => element.id == widget.movie.id);
    final movie =
        matchingMovies.isNotEmpty ? matchingMovies.first : widget.movie;
    final year = DateFormat('yyyy').format(movie.releaseDate);
    final runtime = movie.seasonsCount > 0
        ? '${movie.seasonsCount} season${movie.seasonsCount == 1 ? '' : 's'}'
        : movie.duration > 0
            ? '${movie.duration} min'
            : null;
    final countries = _cleanCommaText(movie.countries);
    final hasDirectors = movie.directors.isNotEmpty;
    final hasActors = movie.actors.isNotEmpty;
    final hasCountries = countries.isNotEmpty;
    final visibleGenres = movie.genres.take(3).toList();
    final movieDiarySignal =
        movie.allVotes > 0 ? 'MovieDiary ${movie.rating}%' : null;
    final imdbSignal = movie.imdbVotes > 0 ? 'IMDb ${movie.imdbRate}' : null;
    final tagline = movie.tagline?.trim();
    final hasTagline = tagline != null && tagline.isNotEmpty;
    final hasCompactSignals = movieDiarySignal != null || imdbSignal != null;
    final useCompactPoster =
        !hasTagline && visibleGenres.isEmpty && !hasCompactSignals;

    return Scaffold(
        backgroundColor: Md3Colors.background,
        appBar: AppBar(
          backgroundColor: Md3Colors.background,
          foregroundColor: Md3Colors.text,
          elevation: 0,
          title: Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (AdManager.bannerVisible && AdManager.bannersReady)
              SizedBox(
                width: 320,
                child: Center(
                  child:
                      AdManager.getBannerWidget(AdManager.itemExpandedBannerAd),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Md3Layout.pageHorizontalInset(context),
            8,
            Md3Layout.pageHorizontalInset(context),
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Md3Card(
                key: const Key('movie-details-hero'),
                padding: const EdgeInsets.all(14),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final stackHero = textScale > 1.45;
                    final posterWidth = useCompactPoster ? 104.0 : 112.0;
                    final posterHeight = useCompactPoster ? 156.0 : 168.0;
                    final details = _buildHeroDetails(
                      movie: movie,
                      year: year,
                      runtime: runtime,
                      visibleGenres: visibleGenres,
                      movieDiarySignal: movieDiarySignal,
                      imdbSignal: imdbSignal,
                      tagline: hasTagline ? tagline : null,
                    );
                    final poster = Md3MoviePoster(
                      movie: movie,
                      width: posterWidth,
                      height: posterHeight,
                    );

                    if (stackHero) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: poster),
                          const SizedBox(height: 16),
                          details,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        poster,
                        const SizedBox(width: 14),
                        Expanded(child: details),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildStatusActionCard(movie),
              if (movie.overview.isNotEmpty) ...[
                const Md3SectionHeader(title: 'Story'),
                Md3Card(
                  child: Md3ExpandableText(
                    key: const Key('movie-story'),
                    text: movie.overview,
                    style: const TextStyle(
                      color: Md3Colors.text,
                      fontSize: 16,
                      height: 23 / 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (hasDirectors || hasActors || hasCountries) ...[
                const Md3SectionHeader(title: 'Details'),
                Md3Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasDirectors)
                        _buildDetailRow(
                          'Directed by',
                          movie.directors.join(', '),
                          isLast: !hasActors && !hasCountries,
                        ),
                      if (hasActors)
                        _buildDetailRow(
                          'Starring',
                          movie.actors.join(', '),
                          isLast: !hasCountries,
                        ),
                      if (hasCountries)
                        _buildDetailRow(
                          'Countries',
                          countries,
                          isLast: true,
                        ),
                    ],
                  ),
                ),
              ],
              buildWhereToWatch(context),
            ],
          ),
        ));
  }

  Widget _buildHeroDetails({
    required Movie movie,
    required String year,
    required String? runtime,
    required List<String> visibleGenres,
    required String? movieDiarySignal,
    required String? imdbSignal,
    required String? tagline,
  }) {
    final metadata = [
      year,
      if (runtime != null) runtime,
      if (movie.seasonsCount > 0)
        movie.inProduction ? 'In production' : 'Ended',
    ].join('  /  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: const TextStyle(
            color: Md3Colors.text,
            fontSize: 22,
            height: 1.08,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          metadata,
          style: const TextStyle(
            color: Md3Colors.muted,
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (tagline != null) ...[
          const SizedBox(height: 12),
          Text(
            tagline,
            style: const TextStyle(
              color: Md3Colors.primary,
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (visibleGenres.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            key: const Key('movie-hero-genres'),
            spacing: 6,
            runSpacing: 6,
            children: visibleGenres.map(_buildHeroGenrePill).toList(),
          ),
        ],
        if (movieDiarySignal != null || imdbSignal != null) ...[
          const SizedBox(height: 12),
          Wrap(
            key: const Key('movie-hero-signals'),
            spacing: 10,
            runSpacing: 8,
            children: [
              if (movieDiarySignal != null) _buildHeroSignal(movieDiarySignal),
              if (imdbSignal != null) _buildHeroSignal(imdbSignal),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHeroGenrePill(String genre) {
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Md3Colors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Md3Colors.border),
      ),
      child: Text(
        genre,
        style: const TextStyle(
          color: Md3Colors.text,
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHeroSignal(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Md3Colors.primary,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildStatusActionCard(Movie movie) {
    final hasStatus = movie.movieRate != MovieRate.notRated;
    final title = hasStatus ? 'Your status' : 'Set your status';
    final detail = movie.movieRate == MovieRate.addedToWatchlist
        ? 'Mark it watched, or choose a different status.'
        : MovieRate.isViewed(movie.movieRate)
            ? 'Change your opinion, or move it to Watchlist.'
            : 'Rate it, or save it to Watchlist.';

    return Md3Card(
      key: const Key('movie-status-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              if (hasStatus) Md3OpinionBadge(movieRate: movie.movieRate),
              Text(
                title,
                style: const TextStyle(
                  color: Md3Colors.text,
                  fontSize: 18,
                  height: 24 / 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          MovieRateButtons(
            movie: movie,
            fromSearch: widget.fromSearch,
            closeParentOnRate: false,
            shouldRequestReview: widget.shouldRequestReview,
            moviesList: widget.moviesList,
          ),
        ],
      ),
    );
  }

  Widget _buildProviderToggle(int totalCount) {
    if (totalCount <= 4) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: Md3Colors.primary,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.only(top: 8, right: 10),
        ),
        onPressed: () {
          setState(() {
            showAllWatchProviders = !showAllWatchProviders;
          });
        },
        icon: Icon(
          showAllWatchProviders
              ? Icons.expand_less_rounded
              : Icons.expand_more_rounded,
          size: 20,
        ),
        label: Text(
          showAllWatchProviders ? 'Show less' : 'Show all $totalCount',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  List<_WatchProviderEntry> _providerEntries(MovieWatchProviderGroup group) {
    return [
      ...group.stream.map(
        (provider) => _WatchProviderEntry('Stream', provider),
      ),
      ...group.rent.map(
        (provider) => _WatchProviderEntry('Rent', provider),
      ),
      ...group.buy.map(
        (provider) => _WatchProviderEntry('Buy', provider),
      ),
    ];
  }

  Widget _buildProviderRows(List<_WatchProviderEntry> entries) {
    final groupedEntries = <String, List<MovieWatchProvider>>{};

    for (final entry in entries) {
      groupedEntries.putIfAbsent(entry.type, () => []).add(entry.provider);
    }

    return Column(
      children: groupedEntries.entries
          .map(
            (entry) => buildProviderRow(
              context,
              entry.key,
              entry.value,
            ),
          )
          .toList(),
    );
  }

  Widget buildWhereToWatch(BuildContext context) {
    return FutureBuilder<MovieWatchProviderGroup>(
      future: whereToWatchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildProviderSection(
            semanticLabel: 'Loading streaming availability',
            child: const Md3ProviderSkeletonList(rows: 2),
          );
        }

        if (snapshot.hasError) {
          return _buildProviderTerminalState(
            title: 'Streaming availability unavailable',
            body:
                'MovieDiary could not check providers right now. Movie details remain available.',
          );
        }

        final group = snapshot.data!;
        final entries = _providerEntries(group);

        if (entries.isEmpty) {
          return _buildProviderTerminalState(
            title: 'No streaming sources listed',
            body:
                'Provider availability can change by region. Retry to check again.',
          );
        }

        final visibleEntries =
            showAllWatchProviders ? entries : entries.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Md3SectionHeader(title: 'Where to Watch'),
            Md3Card(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Md3Colors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${entries.length} source${entries.length == 1 ? '' : 's'} available',
                          style: const TextStyle(
                            color: Md3Colors.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        group.country,
                        style: const TextStyle(
                          color: Md3Colors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildProviderRows(visibleEntries),
                  _buildProviderToggle(entries.length),
                  if (group.sourceLink != null &&
                      group.sourceLink!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Availability from ${group.source ?? 'provider data'}',
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProviderSection({
    required Widget child,
    String? semanticLabel,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Md3SectionHeader(title: 'Where to Watch'),
        Md3Card(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ],
    );

    if (semanticLabel == null) {
      return content;
    }
    return Semantics(
      liveRegion: true,
      label: semanticLabel,
      child: content,
    );
  }

  Widget _buildProviderTerminalState({
    required String title,
    required String body,
  }) {
    return _buildProviderSection(
      semanticLabel: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Md3Colors.text,
              fontSize: 16,
              height: 22 / 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Md3Colors.primary,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: _retryWhereToWatch,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Md3Colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Md3Colors.text,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Divider(height: 1, color: Md3Colors.border),
              )
          ],
        ),
      ),
    );
  }

  String _cleanCommaText(String value) {
    return value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(', ');
  }

  Widget buildProviderRow(
      BuildContext context, String title, List<MovieWatchProvider> providers) {
    if (providers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key: Key('provider-group-$title'),
            title,
            style: const TextStyle(
              color: Md3Colors.primary,
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final halfWidth = (constraints.maxWidth - gap) / 2;
              final textScale = MediaQuery.textScalerOf(context).scale(1);

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: providers.map((provider) {
                  final useHalfWidth = textScale <= 1.3 &&
                      halfWidth >= 132 &&
                      _providerNameFits(
                        context,
                        provider.providerName,
                        halfWidth,
                      );
                  return buildProviderChip(
                    context,
                    provider,
                    width: useHalfWidth ? halfWidth : constraints.maxWidth,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _providerNameFits(
    BuildContext context,
    String providerName,
    double tileWidth,
  ) {
    final availableTextWidth = tileWidth - 66;
    if (availableTextWidth <= 0) {
      return false;
    }

    final painter = TextPainter(
      text: TextSpan(
        text: providerName,
        style: const TextStyle(
          fontSize: 13,
          height: 18 / 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      maxLines: 2,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: availableTextWidth);
    return !painter.didExceedMaxLines;
  }

  Widget buildProviderChip(
    BuildContext context,
    MovieWatchProvider provider, {
    required double width,
  }) {
    return SizedBox(
      key: Key('provider-tile-${provider.providerId}'),
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
        decoration: BoxDecoration(
          color: Md3Colors.background,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          border: Border.all(color: Md3Colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Md3ProviderLogo(
              providerName: provider.providerName,
              logoPath: provider.logoPath,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider.providerName,
                style: const TextStyle(
                  color: Md3Colors.text,
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchProviderEntry {
  final String type;
  final MovieWatchProvider provider;

  const _WatchProviderEntry(this.type, this.provider);
}
