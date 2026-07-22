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

  const MovieListItemExpanded(
      {super.key,
      required this.movie,
      this.fromSearch = false,
      required this.imageUrl,
      this.moviesList,
      this.shouldRequestReview = false});

  @override
  State<StatefulWidget> createState() {
    return MovieListItemExpandedState();
  }
}

class MovieListItemExpandedState extends State<MovieListItemExpanded> {
  late Future<MovieWatchProviderGroup> whereToWatchFuture;
  final serviceAgent = ServiceAgent();
  bool showAllWatchProviders = false;

  @override
  void initState() {
    super.initState();
    whereToWatchFuture =
        serviceAgent.getWhereToWatchGrouped(widget.movie.id, 'US');
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final matchingMovies = moviesState.userMovies
        .where((element) => element.id == widget.movie.id);
    final movie =
        matchingMovies.isNotEmpty ? matchingMovies.first : widget.movie;
    final formatter = NumberFormat("#,###");
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
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Md3Card(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Md3MoviePoster(movie: movie, width: 122, height: 184),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Md3Colors.text,
                              fontSize: 22,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            [
                              year,
                              if (runtime != null) runtime,
                              if (movie.seasonsCount > 0)
                                movie.inProduction ? 'In production' : 'Ended',
                            ].join('  /  '),
                            style: const TextStyle(
                              color: Md3Colors.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (movie.tagline != null &&
                              movie.tagline!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              movie.tagline!,
                              style: const TextStyle(
                                color: Md3Colors.primary,
                                fontSize: 14,
                                height: 1.3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildStatusActionCard(movie),
              if (movie.genres.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: movie.genres
                      .map((genre) => Md3Chip(text: genre, active: false))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildRatingCard(
                      label: 'MovieDiary',
                      value: movie.allVotes > 0 ? '${movie.rating}%' : 'New',
                      detail: movie.allVotes > 0
                          ? '${formatter.format(movie.allVotes)} votes'
                          : 'No votes yet',
                      icon: Icons.favorite_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildRatingCard(
                      label: 'IMDb',
                      value: movie.imdbVotes > 0 ? '${movie.imdbRate}' : 'New',
                      detail: movie.imdbVotes > 0
                          ? '${formatter.format(movie.imdbVotes)} votes'
                          : 'No votes yet',
                      icon: Icons.star_rounded,
                    ),
                  ),
                ],
              ),
              if (movie.overview.isNotEmpty) ...[
                const Md3SectionHeader(title: 'Story'),
                Md3Card(
                  child: Text(
                    movie.overview,
                    style: const TextStyle(
                      color: Md3Colors.text,
                      fontSize: 15,
                      height: 1.45,
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

  Widget _buildStatusActionCard(Movie movie) {
    final hasStatus = movie.movieRate != MovieRate.notRated;
    final title = hasStatus
        ? 'Saved as ${MovieRate.opinionLabel(movie.movieRate)}'
        : 'Set your movie status';
    final detail = movie.movieRate == MovieRate.addedToWatchlist
        ? 'Mark watched when you finish it, or change your rating here.'
        : MovieRate.isViewed(movie.movieRate)
            ? 'Change your opinion or move it back to Watchlist.'
            : 'Rate it if you have seen it, or save it to Watchlist.';

    return Md3Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasStatus) ...[
                Md3OpinionBadge(movieRate: movie.movieRate),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Md3Colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
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

  Widget _buildRatingCard({
    required String label,
    required String value,
    required String detail,
    required IconData icon,
  }) {
    return Md3Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Md3Colors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Md3Colors.text,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
          padding: const EdgeInsets.only(top: 8, right: 10),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final group = snapshot.data!;
        final entries = _providerEntries(group);

        if (entries.isEmpty) {
          return const SizedBox.shrink();
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                title,
                style: const TextStyle(
                  color: Md3Colors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: providers
                  .map((provider) => buildProviderChip(context, provider))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProviderChip(BuildContext context, MovieWatchProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Md3Colors.background,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: Md3Colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.logoPath != null && provider.logoPath!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(5)),
              child: Image.network(
                'https://image.tmdb.org/t/p/w45${provider.logoPath}',
                height: 22,
                width: 22,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) =>
                    loadingProgress == null
                        ? child
                        : const Md3SkeletonBox(
                            width: 22,
                            height: 22,
                            radius: 5,
                          ),
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 22,
                  height: 22,
                  color: Md3Colors.surfaceMuted,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.live_tv_outlined,
                    color: Md3Colors.muted,
                    size: 14,
                  ),
                ),
              ),
            ),
          if (provider.logoPath != null && provider.logoPath!.isNotEmpty)
            const SizedBox(width: 6),
          Text(
            provider.providerName,
            style: const TextStyle(
              color: Md3Colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchProviderEntry {
  final String type;
  final MovieWatchProvider provider;

  const _WatchProviderEntry(this.type, this.provider);
}
