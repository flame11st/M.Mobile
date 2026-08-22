import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Enums/movie_type.dart';
import 'package:mmobile/Enums/recommendation_discovery_level.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/recommendation_history.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/movie_list_item_expanded.dart';
import 'package:provider/provider.dart';

abstract class RecommendationHistoryStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecureRecommendationHistoryStore implements RecommendationHistoryStore {
  const SecureRecommendationHistoryStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class RecommendationsHistoryPage extends StatefulWidget {
  const RecommendationsHistoryPage({
    super.key,
    this.serviceAgent,
    this.store,
  });

  final ServiceAgent? serviceAgent;
  final RecommendationHistoryStore? store;

  @override
  State<RecommendationsHistoryPage> createState() =>
      RecommendationsHistoryPageState();
}

class RecommendationsHistoryPageState
    extends State<RecommendationsHistoryPage> {
  static const _historyTimeout = Duration(seconds: 12);
  static const _minimumSkeletonVisibility = Duration(milliseconds: 500);
  static const _pageSize = 12;

  late final ServiceAgent serviceAgent;
  late final RecommendationHistoryStore store;
  UserState? userState;
  List<RecommendationHistoryBatchSummary> batches = [];
  RecommendationHistoryLegacySummary? legacyArchive;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = false;
  bool _started = false;
  bool _showingCached = false;
  int nextCursor = 0;
  int _requestGeneration = 0;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    serviceAgent = widget.serviceAgent ?? ServiceAgent();
    store = widget.store ?? const SecureRecommendationHistoryStore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userState ??= Provider.of<UserState>(context, listen: false);
    if (_started || userState!.userId == null || userState!.userId!.isEmpty) {
      return;
    }

    _started = true;
    Future.microtask(_restoreThenRefresh);
  }

  Future<void> _restoreThenRefresh() async {
    await _restoreCache();
    await getHistory(reset: true);
  }

  Future<void> _restoreCache() async {
    try {
      final cached = await store.read(_rootCacheKey);
      if (cached == null || cached.isEmpty) {
        return;
      }
      final decoded = jsonDecode(cached);
      if (decoded is! Map) {
        return;
      }
      final page = RecommendationHistoryPageData.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        batches = page.items;
        legacyArchive = page.legacyArchive;
        nextCursor = page.nextCursor;
        hasMore = page.hasMore;
        _showingCached = batches.isNotEmpty || legacyArchive != null;
      });
    } catch (error) {
      debugPrint('Recommendation history cache could not be read: $error');
    }
  }

  Future<void> getHistory({bool reset = false}) async {
    if ((reset && isLoading) || (!reset && (isLoading || isLoadingMore))) {
      return;
    }

    final generation = ++_requestGeneration;
    final stopwatch = Stopwatch()..start();
    final initiallyEmpty = batches.isEmpty && legacyArchive == null;
    setState(() {
      if (reset) {
        isLoading = true;
      } else {
        isLoadingMore = true;
      }
      errorMessage = null;
    });

    try {
      final response = await serviceAgent
          .getRecommendationHistoryBatches(
            userState!.userId!,
            cursor: reset ? 0 : nextCursor,
            pageSize: _pageSize,
          )
          .timeout(_historyTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('History request failed with ${response.statusCode}.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('History response was not an object.');
      }
      final page = RecommendationHistoryPageData.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      await _holdInitialSkeleton(stopwatch, initiallyEmpty);
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      final merged = reset
          ? page.items
          : <RecommendationHistoryBatchSummary>[
              ...batches,
              ...page.items.where(
                (candidate) => batches.every(
                  (existing) => existing.batchId != candidate.batchId,
                ),
              ),
            ];
      setState(() {
        batches = merged;
        legacyArchive = page.legacyArchive ?? legacyArchive;
        nextCursor = page.nextCursor;
        hasMore = page.hasMore;
        isLoading = false;
        isLoadingMore = false;
        _showingCached = false;
      });
      unawaited(_persistRootCache());
    } catch (error) {
      debugPrint('Recommendation history failed: $error');
      await _holdInitialSkeleton(stopwatch, initiallyEmpty);
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        isLoading = false;
        isLoadingMore = false;
        errorMessage =
            'MovieDiary could not load recommendation history. Try again.';
      });
    }
  }

  Future<void> _persistRootCache() async {
    try {
      await store.write(
        _rootCacheKey,
        jsonEncode(
          RecommendationHistoryPageData(
            items: batches,
            nextCursor: nextCursor,
            hasMore: hasMore,
            legacyArchive: legacyArchive,
          ).toJson(),
        ),
      );
    } catch (error) {
      debugPrint('Recommendation history cache could not be saved: $error');
    }
  }

  Future<void> _holdInitialSkeleton(
    Stopwatch stopwatch,
    bool initiallyEmpty,
  ) async {
    if (!initiallyEmpty) {
      return;
    }
    final remaining = _minimumSkeletonVisibility - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  String get _rootCacheKey =>
      'recommendation_history_batches_v2_${userState!.userId}';

  bool get _hasContent => batches.isNotEmpty || legacyArchive != null;

  @override
  Widget build(BuildContext context) {
    final content = isLoading && !_hasContent
        ? const _HistorySkeleton()
        : errorMessage != null && !_hasContent
            ? _HistoryError(message: errorMessage!, onRetry: getHistory)
            : !_hasContent
                ? const _EmptyHistory()
                : _buildHistoryList();

    return Scaffold(
      backgroundColor: Md3Colors.background,
      body: Scaffold(
        backgroundColor: Md3Colors.background,
        appBar: AppBar(
          title: const Text('Recommendation history'),
          backgroundColor: Md3Colors.background,
          foregroundColor: Md3Colors.text,
          elevation: 0,
        ),
        body: content,
      ),
    );
  }

  Widget _buildHistoryList() {
    final entries = batches.length + (legacyArchive == null ? 0 : 1);
    return RefreshIndicator(
      onRefresh: () => getHistory(reset: true),
      color: Md3Colors.primary,
      child: ListView.builder(
        key: const Key('recommendation-history-batch-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Md3Layout.pageHorizontalInset(context),
          Md3Spacing.x8,
          Md3Layout.pageHorizontalInset(context),
          Md3Spacing.x24,
        ),
        itemCount: entries + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                if (isLoading || _showingCached || errorMessage != null)
                  _HistoryStatusBanner(
                    message: errorMessage != null
                        ? 'Showing saved history. MovieDiary could not refresh it right now.'
                        : 'Refreshing your saved recommendation sessions',
                    isLoading: isLoading && errorMessage == null,
                    onRetry: errorMessage == null
                        ? null
                        : () => getHistory(reset: true),
                  ),
                const _HistoryIntro(),
              ],
            );
          }
          if (index == entries + 1) {
            if (!hasMore && !isLoadingMore) {
              return const SizedBox(height: Md3Spacing.x8);
            }
            return Padding(
              padding: const EdgeInsets.only(top: Md3Spacing.x8),
              child: Center(
                child: isLoadingMore
                    ? const CircularProgressIndicator.adaptive()
                    : TextButton.icon(
                        key: const Key('recommendation-history-load-more'),
                        onPressed: () => getHistory(),
                        icon: const Icon(Icons.expand_more_rounded),
                        label: const Text('Load older sessions'),
                      ),
              ),
            );
          }

          final entryIndex = index - 1;
          if (entryIndex < batches.length) {
            final batch = batches[entryIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: Md3Spacing.x12),
              child: _HistoryBatchCard(
                key: ValueKey('history-batch-${batch.batchId}'),
                summary: batch,
                onTap: () => _openBatch(batch),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: Md3Spacing.x12),
            child: _LegacyHistoryCard(
              summary: legacyArchive!,
              onTap: _openLegacyArchive,
            ),
          );
        },
      ),
    );
  }

  void _openBatch(RecommendationHistoryBatchSummary summary) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecommendationHistoryDetailPage.batch(
          userId: userState!.userId!,
          summary: summary,
          serviceAgent: serviceAgent,
          store: store,
        ),
      ),
    );
  }

  void _openLegacyArchive() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecommendationHistoryDetailPage.legacy(
          userId: userState!.userId!,
          legacySummary: legacyArchive!,
          serviceAgent: serviceAgent,
          store: store,
        ),
      ),
    );
  }
}

class RecommendationHistoryDetailPage extends StatefulWidget {
  const RecommendationHistoryDetailPage.batch({
    super.key,
    required this.userId,
    required this.summary,
    required this.serviceAgent,
    required this.store,
  }) : legacySummary = null;

  const RecommendationHistoryDetailPage.legacy({
    super.key,
    required this.userId,
    required this.legacySummary,
    required this.serviceAgent,
    required this.store,
  }) : summary = null;

  final String userId;
  final RecommendationHistoryBatchSummary? summary;
  final RecommendationHistoryLegacySummary? legacySummary;
  final ServiceAgent serviceAgent;
  final RecommendationHistoryStore store;

  bool get isLegacy => legacySummary != null;

  @override
  State<RecommendationHistoryDetailPage> createState() =>
      _RecommendationHistoryDetailPageState();
}

class _RecommendationHistoryDetailPageState
    extends State<RecommendationHistoryDetailPage> {
  static const _timeout = Duration(seconds: 12);
  static const _legacyPageSize = 20;
  List<RecommendationHistoryItem> items = [];
  RecommendationHistoryBatchDetail? detail;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = false;
  bool _showingCached = false;
  int nextCursor = 0;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_restoreThenLoad);
  }

  Future<void> _restoreThenLoad() async {
    await _restoreCache();
    await _load(reset: true);
  }

  Future<void> _restoreCache() async {
    try {
      final cached = await widget.store.read(_cacheKey);
      if (cached == null || cached.isEmpty) {
        return;
      }
      final decoded = jsonDecode(cached);
      if (decoded is! Map) {
        return;
      }
      if (widget.isLegacy) {
        final page = RecommendationHistoryLegacyPage.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        if (!mounted) {
          return;
        }
        setState(() {
          items = page.items;
          nextCursor = page.nextCursor;
          hasMore = page.hasMore;
          _showingCached = items.isNotEmpty;
          isLoading = false;
        });
      } else {
        final restored = RecommendationHistoryBatchDetail.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        if (!mounted) {
          return;
        }
        setState(() {
          detail = restored;
          items = restored.items;
          _showingCached = items.isNotEmpty;
          isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Recommendation history detail cache read failed: $error');
    }
  }

  Future<void> _load({bool reset = false}) async {
    if ((reset && isLoading && !_showingCached) || isLoadingMore) {
      if (!reset) {
        return;
      }
    }
    setState(() {
      if (reset) {
        isLoading = true;
      } else {
        isLoadingMore = true;
      }
      errorMessage = null;
    });

    try {
      final response = widget.isLegacy
          ? await widget.serviceAgent
              .getLegacyRecommendationHistory(
                widget.userId,
                cursor: reset ? 0 : nextCursor,
                pageSize: _legacyPageSize,
              )
              .timeout(_timeout)
          : await widget.serviceAgent
              .getRecommendationHistoryBatchDetail(
                widget.userId,
                widget.summary!.batchId,
              )
              .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('History detail failed with ${response.statusCode}.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('History detail was not an object.');
      }
      if (!mounted) {
        return;
      }

      if (widget.isLegacy) {
        final page = RecommendationHistoryLegacyPage.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        setState(() {
          items = reset ? page.items : [...items, ...page.items];
          nextCursor = page.nextCursor;
          hasMore = page.hasMore;
          isLoading = false;
          isLoadingMore = false;
          _showingCached = false;
        });
        unawaited(
          _persistCache(
            jsonEncode(
              RecommendationHistoryLegacyPage(
                items: items,
                nextCursor: nextCursor,
                hasMore: hasMore,
                totalCount: widget.legacySummary!.itemCount,
              ).toJson(),
            ),
          ),
        );
      } else {
        final loaded = RecommendationHistoryBatchDetail.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        setState(() {
          detail = loaded;
          items = loaded.items;
          isLoading = false;
          isLoadingMore = false;
          _showingCached = false;
        });
        unawaited(_persistCache(jsonEncode(loaded.toJson())));
      }
    } catch (error) {
      debugPrint('Recommendation history detail failed: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        isLoading = false;
        isLoadingMore = false;
        errorMessage = 'This recommendation session could not be loaded.';
      });
    }
  }

  String get _cacheKey => widget.isLegacy
      ? 'recommendation_history_legacy_v2_${widget.userId}'
      : 'recommendation_history_detail_v2_${widget.userId}_${widget.summary!.batchId}';

  Future<void> _persistCache(String payload) async {
    try {
      await widget.store.write(_cacheKey, payload);
    } catch (error) {
      debugPrint('Recommendation history detail cache write failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Md3Colors.background,
      appBar: AppBar(
        title: Text(widget.isLegacy ? 'Earlier recommendations' : 'Saved deck'),
        backgroundColor: Md3Colors.background,
        foregroundColor: Md3Colors.text,
        elevation: 0,
      ),
      body: isLoading && items.isEmpty
          ? const _HistorySkeleton()
          : errorMessage != null && items.isEmpty
              ? _HistoryError(message: errorMessage!, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      color: Md3Colors.primary,
      child: ListView.builder(
        key: const Key('recommendation-history-detail-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Md3Layout.pageHorizontalInset(context),
          Md3Spacing.x8,
          Md3Layout.pageHorizontalInset(context),
          Md3Spacing.x24,
        ),
        itemCount: items.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                if (_showingCached || errorMessage != null)
                  _HistoryStatusBanner(
                    message: errorMessage != null
                        ? 'Showing the saved copy. MovieDiary could not refresh it right now.'
                        : 'Refreshing this saved recommendation session',
                    isLoading: errorMessage == null,
                    onRetry:
                        errorMessage == null ? null : () => _load(reset: true),
                  ),
                _DetailHeader(
                  summary: widget.summary,
                  legacySummary: widget.legacySummary,
                  loadedItemCount: items.length,
                ),
                const SizedBox(height: Md3Spacing.x12),
              ],
            );
          }
          if (index == items.length + 1) {
            if (!widget.isLegacy || (!hasMore && !isLoadingMore)) {
              return const SizedBox(height: Md3Spacing.x8);
            }
            return Center(
              child: isLoadingMore
                  ? const CircularProgressIndicator.adaptive()
                  : TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Load older picks'),
                    ),
            );
          }
          final item = items[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: Md3Spacing.x12),
            child: _HistoryItemCard(
              key: ValueKey('history-item-${item.rank}-${item.movie.id}'),
              item: item,
              isLegacy: widget.isLegacy,
              onTap: () => _openMovie(item.movie),
            ),
          );
        },
      ),
    );
  }

  void _openMovie(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MovieListItemExpanded(
          movie: movie,
          imageUrl: 'https://moviediarystorage.blob.core.windows.net/movies',
        ),
      ),
    );
  }
}

class _HistoryIntro extends StatelessWidget {
  const _HistoryIntro();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(4, Md3Spacing.x8, 4, Md3Spacing.x16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Revisit each deck exactly as it was generated.',
          style: TextStyle(
            color: Md3Colors.muted,
            fontSize: 15,
            height: 21 / 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _HistoryBatchCard extends StatelessWidget {
  const _HistoryBatchCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  final RecommendationHistoryBatchSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mediaLabel = summary.movieType == MovieType.tv ? 'TV' : 'Movies';
    final modeLabel = _modeLabel(summary.discoveryLevel);
    final date =
        DateFormat('MMM d, yyyy').format(summary.generatedAt.toLocal());
    final semantics =
        '$date, $mediaLabel, $modeLabel, ${summary.itemCount} picks. Open deck.';

    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: Md3Card(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    date,
                    style: const TextStyle(
                      color: Md3Colors.text,
                      fontSize: 20,
                      height: 25 / 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Md3Colors.primary,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: Md3Spacing.x8),
            Wrap(
              spacing: Md3Spacing.x8,
              runSpacing: Md3Spacing.x8,
              children: [
                _MetadataPill(label: mediaLabel),
                _MetadataPill(label: modeLabel),
                _MetadataPill(label: '${summary.itemCount} picks'),
              ],
            ),
            const SizedBox(height: Md3Spacing.x16),
            _PosterStrip(movies: summary.previewItems),
          ],
        ),
      ),
    );
  }
}

class _LegacyHistoryCard extends StatelessWidget {
  const _LegacyHistoryCard({
    required this.summary,
    required this.onTap,
  });

  final RecommendationHistoryLegacySummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Earlier recommendations, ${summary.itemCount} picks. Open archive.',
      excludeSemantics: true,
      child: Md3Card(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Earlier recommendations',
                    style: TextStyle(
                      color: Md3Colors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Md3Colors.primary,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: Md3Spacing.x8),
            Text(
              '${summary.itemCount} picks saved before decks carried session details.',
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Md3Spacing.x16),
            _PosterStrip(movies: summary.previewItems),
          ],
        ),
      ),
    );
  }
}

class _PosterStrip extends StatelessWidget {
  const _PosterStrip({required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return Container(
        height: 78,
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Icon(Icons.movie_outlined, color: Md3Colors.muted),
            SizedBox(width: Md3Spacing.x8),
            Text(
              'Poster preview unavailable',
              style: TextStyle(color: Md3Colors.muted),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: movies.take(4).length,
        separatorBuilder: (_, __) => const SizedBox(width: Md3Spacing.x8),
        itemBuilder: (context, index) => Md3MoviePoster(
          movie: movies[index],
          width: 54,
          height: 82,
          hydrateMissingPoster: false,
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.summary,
    required this.legacySummary,
    required this.loadedItemCount,
  });

  final RecommendationHistoryBatchSummary? summary;
  final RecommendationHistoryLegacySummary? legacySummary;
  final int loadedItemCount;

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return Md3Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earlier recommendations',
              style: TextStyle(
                color: Md3Colors.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: Md3Spacing.x8),
            Text(
              '$loadedItemCount of ${legacySummary!.itemCount} picks. Session mode and match evidence were not saved for these older recommendations.',
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 15,
                height: 21 / 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final media = summary!.movieType == MovieType.tv ? 'TV' : 'Movies';
    final mode = _modeLabel(summary!.discoveryLevel);
    final date =
        DateFormat('MMMM d, yyyy').format(summary!.generatedAt.toLocal());
    return Md3Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$mode $media deck',
            style: const TextStyle(
              color: Md3Colors.text,
              fontSize: 22,
              height: 27 / 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: Md3Spacing.x8),
          Text(
            '$date  •  ${summary!.itemCount} picks',
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 15,
              height: 21 / 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Md3Spacing.x8),
          const Text(
            'Ranks and explanations are preserved from the generated deck.',
            style: TextStyle(
              color: Md3Colors.muted,
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  const _HistoryItemCard({
    super.key,
    required this.item,
    required this.isLegacy,
    required this.onTap,
  });

  final RecommendationHistoryItem item;
  final bool isLegacy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final movie = item.movie;
    final year =
        movie.releaseDate.year > 1900 ? '${movie.releaseDate.year}' : '';
    final genres = movie.genres.take(2).join(' • ');
    final action = _actionPresentation(item.userAction, movie.movieRate);
    final fallbackExplanation = isLegacy
        ? 'The explanation was not stored for this earlier recommendation.'
        : 'The explanation was not available for this saved deck.';
    final explanation = item.explanation?.trim().isNotEmpty == true
        ? item.explanation!.trim()
        : fallbackExplanation;
    final semantics = [
      'Rank ${item.rank}',
      movie.title,
      if (item.matchLabel != null) item.matchLabel!,
      explanation,
      action.label,
      'Open details',
    ].join('. ');

    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: Md3Card(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Md3MoviePoster(
                  movie: movie,
                  width: 72,
                  height: 108,
                  hydrateMissingPoster: false,
                ),
                const SizedBox(width: Md3Spacing.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${item.rank}',
                        style: const TextStyle(
                          color: Md3Colors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        movie.title,
                        style: const TextStyle(
                          color: Md3Colors.text,
                          fontSize: 19,
                          height: 24 / 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (year.isNotEmpty || genres.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [year, genres]
                              .where((part) => part.isNotEmpty)
                              .join('  •  '),
                          style: const TextStyle(
                            color: Md3Colors.muted,
                            fontSize: 13,
                            height: 18 / 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: Md3Spacing.x8),
                      Wrap(
                        spacing: Md3Spacing.x8,
                        runSpacing: Md3Spacing.x8,
                        children: [
                          if (item.matchLabel != null)
                            _MetadataPill(label: item.matchLabel!),
                          _ActionPill(
                            label: action.label,
                            icon: action.icon,
                            color: action.color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Md3Colors.primary,
                ),
              ],
            ),
            const SizedBox(height: Md3Spacing.x12),
            const Text(
              'Why this pick',
              style: TextStyle(
                color: Md3Colors.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              explanation,
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 14,
                height: 20 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Md3Colors.primarySoft,
        borderRadius: BorderRadius.circular(Md3Radius.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Md3Colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Md3Radius.pill),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(icon, size: 15, color: color),
              ),
            ),
            TextSpan(text: label),
          ],
        ),
        softWrap: true,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HistoryStatusBanner extends StatelessWidget {
  const _HistoryStatusBanner({
    required this.message,
    this.isLoading = false,
    this.onRetry,
  });

  final String message;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: Md3Spacing.x8),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: Md3Colors.primarySoft,
          borderRadius: BorderRadius.circular(Md3Radius.medium),
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
            const SizedBox(width: Md3Spacing.x8),
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
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Loading recommendation history',
      child: const Padding(
        padding: EdgeInsets.fromLTRB(
          Md3Spacing.x16,
          Md3Spacing.x12,
          Md3Spacing.x16,
          Md3Spacing.x24,
        ),
        child: Md3ListSkeletonCard(rows: 4),
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Md3Page(
      child: Md3Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: Md3Colors.primary,
              size: 28,
            ),
            const SizedBox(height: Md3Spacing.x12),
            const Text(
              'History unavailable',
              style: TextStyle(
                color: Md3Colors.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: Md3Spacing.x8),
            Text(
              message,
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 15,
                height: 21 / 15,
              ),
            ),
            const SizedBox(height: Md3Spacing.x16),
            Md3PrimaryButton(
              text: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Md3Page(
      child: Md3Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              color: Md3Colors.primary,
              size: 30,
            ),
            const SizedBox(height: Md3Spacing.x12),
            const Text(
              'No recommendation history yet',
              style: TextStyle(
                color: Md3Colors.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: Md3Spacing.x8),
            const Text(
              'Start a discovery deck to save it here.',
              style: TextStyle(
                color: Md3Colors.muted,
                fontSize: 15,
                height: 21 / 15,
              ),
            ),
            const SizedBox(height: Md3Spacing.x16),
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
  }
}

String _modeLabel(RecommendationDiscoveryLevel level) {
  return switch (level) {
    RecommendationDiscoveryLevel.safe => 'Familiar',
    RecommendationDiscoveryLevel.balanced => 'Balanced',
    RecommendationDiscoveryLevel.adventurous => 'Adventurous',
  };
}

({String label, IconData icon, Color color}) _actionPresentation(
  String action,
  int movieRate,
) {
  if (action == 'watchlisted') {
    return (
      label: 'Saved to Watchlist',
      icon: Icons.bookmark_added_rounded,
      color: Md3Colors.primary,
    );
  }
  if (action == 'seen-rated') {
    return (
      label: 'Rated ${MovieRate.opinionLabel(movieRate)}',
      icon: Icons.check_circle_outline_rounded,
      color: Md3Colors.success,
    );
  }
  return (
    label: 'No action yet',
    icon: Icons.radio_button_unchecked_rounded,
    color: Md3Colors.muted,
  );
}
