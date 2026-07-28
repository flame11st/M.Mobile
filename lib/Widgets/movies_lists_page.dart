import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mmobile/Enums/movie_list_type.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:mmobile/Widgets/movies_list_page.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:provider/provider.dart';
import 'Providers/movies_state.dart';

class MoviesListsPage extends StatefulWidget {
  final int initialPageIndex;
  final ServiceAgent? serviceAgent;
  final FlutterSecureStorage? storage;

  const MoviesListsPage({
    super.key,
    required this.initialPageIndex,
    this.serviceAgent,
    this.storage,
  });

  @override
  State<MoviesListsPage> createState() => MoviesListsPageState();
}

class MoviesListsPageState extends State<MoviesListsPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  late final ServiceAgent serviceAgent;
  late final FlutterSecureStorage storage;
  final _generalScrollController = ScrollController();
  final _personalScrollController = ScrollController();
  late int _activeTabIndex;
  bool showGeneralGuidance = true;
  bool _guidanceStateLoading = true;
  String? _loadedGuidanceKey;

  @override
  void initState() {
    super.initState();
    serviceAgent = widget.serviceAgent ?? ServiceAgent();
    storage = widget.storage ?? const FlutterSecureStorage();
    _activeTabIndex = widget.initialPageIndex.clamp(0, 1).toInt();
    tabController = TabController(
      vsync: this,
      length: 2,
      initialIndex: _activeTabIndex,
    );
    tabController.addListener(_handleTabControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userState = Provider.of<UserState>(context);
    final userId = userState.userId?.trim();
    final profileKey = userId != null && userId.isNotEmpty
        ? userId
        : userState.isIncognitoMode
            ? 'anonymous'
            : 'signed-out';
    final guidanceKey = 'movieListsGeneralGuidanceDismissed.$profileKey';

    if (_loadedGuidanceKey == guidanceKey) {
      return;
    }

    _loadedGuidanceKey = guidanceKey;
    _guidanceStateLoading = true;
    showGeneralGuidance = true;
    unawaited(loadGuidanceState(guidanceKey));
  }

  @override
  void dispose() {
    tabController.removeListener(_handleTabControllerChanged);
    tabController.dispose();
    _generalScrollController.dispose();
    _personalScrollController.dispose();

    super.dispose();
  }

  Future<void> handleActiveTabTap() async {
    final controller = _activeTabIndex == 1
        ? _personalScrollController
        : _generalScrollController;
    if (!controller.hasClients) {
      return;
    }

    await controller.animateTo(
      0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleTabControllerChanged() {
    final nextIndex = tabController.index;
    if (_activeTabIndex == nextIndex) {
      return;
    }

    setState(() {
      _activeTabIndex = nextIndex;
    });
  }

  void _selectTab(int index) {
    if (index == _activeTabIndex) {
      unawaited(handleActiveTabTap());
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    tabController.animateTo(
      index,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> loadGuidanceState(String guidanceKey) async {
    String? dismissed;
    try {
      dismissed = await storage.read(key: guidanceKey);
    } catch (error) {
      debugPrint('Lists guidance state could not be read: $error');
    }

    if (!mounted || _loadedGuidanceKey != guidanceKey) {
      return;
    }

    setState(() {
      showGeneralGuidance = dismissed != 'true';
      _guidanceStateLoading = false;
    });
  }

  void dismissGeneralGuidance() {
    final guidanceKey = _loadedGuidanceKey;
    if (guidanceKey == null || !showGeneralGuidance) {
      return;
    }

    setState(() {
      showGeneralGuidance = false;
    });

    unawaited(
      storage.write(key: guidanceKey, value: 'true').catchError((Object error) {
        debugPrint('Lists guidance dismissal could not be saved: $error');
      }),
    );
  }

  Widget getMovieListWidget(MoviesList moviesList, MovieListType type) {
    void openList() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => MoviesListPage(moviesList: moviesList),
        ),
      );
    }

    return Semantics(
      button: true,
      label:
          'Open ${moviesList.name}, ${moviesList.listMovies.length} ${moviesList.listMovies.length == 1 ? 'item' : 'items'}',
      onTap: openList,
      excludeSemantics: true,
      child: Md3Card(
        key: ValueKey('list-card-${type.name}-${moviesList.name}'),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        borderRadius: 20,
        onTap: openList,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 112),
          child: Row(
            children: [
              _ListCoverCollage(
                key: ValueKey('list-cover-${moviesList.name}'),
                listName: moviesList.name,
                movies: moviesList.listMovies,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moviesList.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Md3Colors.text,
                        fontSize: 18,
                        height: 1.28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${moviesList.listMovies.length} item${moviesList.listMovies.length == 1 ? '' : 's'}',
                      maxLines: 1,
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 13,
                        height: 1.38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Tooltip(
                message: 'Open list',
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Md3Colors.muted,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard({
    required String eyebrow,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Md3Card(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Md3Colors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Md3Colors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: Md3Colors.primary,
                    fontSize: 12,
                    height: 1.33,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: Md3Colors.text,
                    fontSize: 22,
                    height: 1.23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralGuidance() {
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration =
        animationsDisabled ? Duration.zero : const Duration(milliseconds: 160);
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: duration,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: !showGeneralGuidance || _guidanceStateLoading
          ? const SizedBox.shrink(key: Key('general-intro-hidden'))
          : SizedBox(
              key: const Key('general-intro'),
              height: textScale > 1.5 ? 240 : 176,
              child: Md3Card(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GENERAL',
                            maxLines: 1,
                            style: TextStyle(
                              color: Md3Colors.primary,
                              fontSize: 12,
                              height: 1.33,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Curated collections',
                            maxLines: textScale > 1.5 ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Md3Colors.text,
                              fontSize: 22,
                              height: 1.23,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Explore staff picks, classics, and popular themes.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Md3Colors.muted,
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          tooltip: 'Dismiss introduction',
                          onPressed: dismissGeneralGuidance,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Md3Colors.muted,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildPersonalEmptyState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Md3Card(
          key: const Key('personal-lists-empty-state'),
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Md3Colors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmarks_rounded,
                  color: Md3Colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Create your first personal list',
                style: TextStyle(
                  color: Md3Colors.text,
                  fontSize: 22,
                  height: 1.23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Group movies for a trip, mood, marathon, or anything else.',
                style: TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 16,
                  height: 1.44,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Md3PrimaryButton(
                key: const Key('personal-empty-create-list'),
                text: 'Create List',
                icon: Icons.add_rounded,
                height:
                    MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 72 : 48,
                onPressed: addNewList,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLoadingState(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_motion_outlined,
                color: Md3Colors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Md3ListSkeletonCard(
          rows: 3,
          posterWidth: 86,
          posterHeight: 72,
          cardPadding: 12,
          itemSpacing: 12,
          trailingSize: 24,
          cardMargin: EdgeInsets.zero,
          cardRadius: 20,
        ),
      ],
    );
  }

  Widget buildGeneralEmptyState() {
    return _buildMessageCard(
      eyebrow: 'GENERAL',
      title: 'Curated lists are unavailable',
      description:
          'MovieDiary could not load its curated collections. Your personal lists are unaffected; reopen Lists when the connection returns.',
      icon: Icons.cloud_off_outlined,
    );
  }

  Future<void> addNewList() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final order = getMaxListOrder(moviesState.personalMoviesLists) + 1;

    final createdName = await showMd3BottomSheet<String>(
      context: context,
      builder: (sheetContext) => _CreateListSheet(
        moviesState: moviesState,
        userState: userState,
        serviceAgent: serviceAgent,
        order: order,
      ),
    );

    if (!mounted || createdName == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Created $createdName',
        Directionality.of(context),
      );
    });

    MSnackBar.showWithMessenger(
      ScaffoldMessenger.of(context),
      'Created $createdName',
      true,
      duration: const Duration(milliseconds: 2500),
      bottomMargin: Md3NavigationMetrics.contentBottomInset(context),
    );

    if (_personalScrollController.hasClients) {
      await _personalScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget buildListsScrollView({
    required List<Widget> children,
    required EdgeInsets padding,
    required ScrollController scrollController,
  }) {
    return ListView(
      controller: scrollController,
      padding: padding,
      children: children,
    );
  }

  int getMaxListOrder(List<MoviesList> lists) {
    var order = lists.isEmpty
        ? 0
        : lists
            .reduce((curr, next) => curr.order > next.order ? curr : next)
            .order;

    return order;
  }

  Widget _buildSegmentedBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Md3LiquidGlass(
        key: const Key('lists-segmented-bar'),
        blur: 20,
        padding: const EdgeInsets.all(3),
        borderRadius: BorderRadius.circular(24),
        tint: Colors.white.withValues(alpha: 0.8),
        borderColor: Colors.white.withValues(alpha: 0.88),
        shadows: const [
          BoxShadow(
            color: Color(0x120f253d),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              _ListsSegment(
                key: const Key('lists-tab-general'),
                label: 'General',
                icon: Icons.public_rounded,
                selected: _activeTabIndex == 0,
                onTap: () => _selectTab(0),
              ),
              _ListsSegment(
                key: const Key('lists-tab-personal'),
                label: 'Personal',
                icon: Icons.bookmarks_rounded,
                selected: _activeTabIndex == 1,
                onTap: () => _selectTab(1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    moviesState.externalMoviesLists.sort((a, b) => a.order.compareTo(b.order));
    moviesState.personalMoviesLists.sort((a, b) => a.order.compareTo(b.order));
    final rootContentInset = Md3NavigationMetrics.contentBottomInset(context);
    final hasPersonalLists = moviesState.personalMoviesLists.isNotEmpty;
    final personalIsEmpty =
        moviesState.isMoviesListsRequested && !hasPersonalLists;

    return Scaffold(
      backgroundColor: Md3Colors.background,
      appBar: AdManager.bannerVisible && AdManager.bannersReady
          ? AppBar(
              title: Center(
                child: AdManager.getBannerWidget(AdManager.listsBannerAd),
              ),
              automaticallyImplyLeading: false,
              elevation: 0,
              backgroundColor: Md3Colors.background,
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Semantics(
                header: true,
                child: const Text(
                  'Lists',
                  key: Key('lists-page-title'),
                  style: TextStyle(
                    color: Md3Colors.text,
                    fontSize: 32,
                    height: 1.19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSegmentedBar(),
            const SizedBox(height: 6),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  buildListsScrollView(
                    scrollController: _generalScrollController,
                    padding: EdgeInsets.fromLTRB(
                      12,
                      10,
                      12,
                      rootContentInset + 16,
                    ),
                    children: [
                      _buildGeneralGuidance(),
                      if (showGeneralGuidance && !_guidanceStateLoading)
                        const SizedBox(height: 6),
                      if (!moviesState.isMoviesListsRequested)
                        buildLoadingState('Loading curated lists...'),
                      if (moviesState.isMoviesListsRequested &&
                          moviesState.externalMoviesLists.isEmpty)
                        buildGeneralEmptyState(),
                      if (moviesState.externalMoviesLists.isNotEmpty)
                        for (final moviesList
                            in moviesState.externalMoviesLists)
                          getMovieListWidget(
                            moviesList,
                            MovieListType.external,
                          ),
                    ],
                  ),
                  Stack(
                    children: [
                      buildListsScrollView(
                        scrollController: _personalScrollController,
                        padding: EdgeInsets.fromLTRB(
                          12,
                          personalIsEmpty ? 18 : 10,
                          12,
                          rootContentInset + (hasPersonalLists ? 80 : 24),
                        ),
                        children: [
                          if (!moviesState.isMoviesListsRequested)
                            buildLoadingState('Loading your lists...'),
                          if (personalIsEmpty) buildPersonalEmptyState(),
                          if (hasPersonalLists)
                            for (final moviesList
                                in moviesState.personalMoviesLists)
                              getMovieListWidget(
                                moviesList,
                                MovieListType.personal,
                              ),
                        ],
                      ),
                      if (moviesState.isMoviesListsRequested &&
                          hasPersonalLists)
                        Positioned(
                          right: 16,
                          bottom: rootContentInset + 4,
                          child: SizedBox(
                            height: 56,
                            width: 56,
                            child: FloatingActionButton(
                              key: const Key('personal-lists-add-fab'),
                              onPressed: addNewList,
                              backgroundColor: Md3Colors.primary,
                              foregroundColor: Colors.white,
                              tooltip: 'Create list',
                              child: const Icon(Icons.add_rounded, size: 28),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListsSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ListsSegment({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Md3Colors.text : Md3Colors.muted;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label lists',
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? Md3Colors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: selected
                    ? Border.all(color: Colors.white.withValues(alpha: 0.94))
                    : null,
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x160f253d),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: foreground, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListCoverCollage extends StatelessWidget {
  final String listName;
  final List<Movie> movies;

  const _ListCoverCollage({
    super.key,
    required this.listName,
    required this.movies,
  });

  bool _hasUsablePoster(Movie movie) {
    final posterPath = movie.posterPath.trim();
    return posterPath.isNotEmpty && posterPath.toLowerCase() != 'null';
  }

  Widget _poster(
    Movie movie,
    int index, {
    required double width,
    required double height,
  }) {
    return SizedBox(
      key: ValueKey('list-cover-$listName-tile-$index'),
      width: width,
      height: height,
      child: Md3MoviePoster(
        movie: movie,
        width: width,
        height: height,
        borderRadius: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview =
        movies.where(_hasUsablePoster).take(3).toList(growable: false);

    return Semantics(
      image: true,
      label: preview.isEmpty
          ? '$listName collection cover'
          : '$listName poster collage',
      excludeSemantics: true,
      child: SizedBox(
        width: 84,
        height: 96,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: switch (preview.length) {
            0 => Container(
                key: ValueKey('list-cover-$listName-fallback'),
                color: Md3Colors.primarySoft,
                child: const Center(
                  child: Icon(
                    Icons.collections_bookmark_rounded,
                    color: Md3Colors.primary,
                    size: 28,
                  ),
                ),
              ),
            1 => _poster(preview[0], 0, width: 84, height: 96),
            2 => Row(
                children: [
                  _poster(preview[0], 0, width: 42, height: 96),
                  _poster(preview[1], 1, width: 42, height: 96),
                ],
              ),
            _ => Row(
                children: [
                  _poster(preview[0], 0, width: 42, height: 96),
                  Column(
                    children: [
                      _poster(preview[1], 1, width: 42, height: 48),
                      _poster(preview[2], 2, width: 42, height: 48),
                    ],
                  ),
                ],
              ),
          },
        ),
      ),
    );
  }
}

class _CreateListSheet extends StatefulWidget {
  final MoviesState moviesState;
  final UserState userState;
  final ServiceAgent serviceAgent;
  final int order;

  const _CreateListSheet({
    required this.moviesState,
    required this.userState,
    required this.serviceAgent,
    required this.order,
  });

  @override
  State<_CreateListSheet> createState() => _CreateListSheetState();
}

class _CreateListSheetState extends State<_CreateListSheet> {
  static const _suggestions = [
    'Favorites',
    'Best Sci-Fi',
    'Weekend Picks',
  ];
  static const _maximumNameLength = 60;

  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;
  String? _requestError;

  String get _trimmedName => _nameController.text.trim();

  bool get _isDuplicate {
    final normalized = _trimmedName.toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    return widget.moviesState.personalMoviesLists.any(
      (list) => list.name.trim().toLowerCase() == normalized,
    );
  }

  bool get _canSubmit =>
      !_submitting && _trimmedName.isNotEmpty && !_isDuplicate;

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setSuggestedName(String name) {
    _nameController.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
    setState(() {
      _requestError = null;
    });
    _focusNode.requestFocus();
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }

    final listName = _trimmedName;
    setState(() {
      _submitting = true;
      _requestError = null;
    });

    await widget.moviesState.addMoviesList(listName, widget.order);
    var shouldRollback = true;

    try {
      final userId = widget.userState.userId?.trim();
      if (userId != null && userId.isNotEmpty) {
        final dynamic response = await widget.serviceAgent
            .createUserMoviesList(userId, listName, widget.order);
        final statusCode = response.statusCode as int;
        if (statusCode < 200 || statusCode >= 300) {
          throw StateError('Create list returned HTTP $statusCode.');
        }
      }

      shouldRollback = false;
      if (mounted) {
        Navigator.of(context).pop(listName);
      }
    } catch (error, stackTrace) {
      debugPrint('Personal list create failed: $error');
      debugPrint('$stackTrace');
      if (!mounted) {
        return;
      }

      setState(() {
        _submitting = false;
        _requestError =
            'MovieDiary could not create this list. Check your connection, then retry.';
      });
    } finally {
      if (shouldRollback) {
        widget.moviesState.removeMoviesList(listName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final duplicateError =
        _isDuplicate ? 'A list with this name already exists.' : null;

    return PopScope(
      canPop: !_submitting,
      child: Md3BottomSheetSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create personal list',
                        style: TextStyle(
                          color: Md3Colors.text,
                          fontSize: 24,
                          height: 1.21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Give this collection a short, memorable name.',
                        style: TextStyle(
                          color: Md3Colors.muted,
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed:
                        _submitting ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Md3Colors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('create-list-name-field'),
              controller: _nameController,
              focusNode: _focusNode,
              autofocus: true,
              enabled: !_submitting,
              maxLength: _maximumNameLength,
              buildCounter: (
                context, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) =>
                  null,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                setState(() {
                  _requestError = null;
                });
              },
              onSubmitted: (_) {
                if (_canSubmit) {
                  unawaited(_submit());
                }
              },
              decoration: InputDecoration(
                labelText: 'List name',
                hintText: 'Best Sci-Fi',
                filled: true,
                fillColor: Md3Colors.background,
                constraints: const BoxConstraints(minHeight: 52),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Md3Colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: duplicateError == null
                        ? Md3Colors.border
                        : Md3Colors.danger,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: duplicateError == null
                        ? Md3Colors.primary
                        : Md3Colors.danger,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: duplicateError != null,
                      child: Text(
                        duplicateError ?? '',
                        style: const TextStyle(
                          color: Md3Colors.danger,
                          fontSize: 13,
                          height: 1.38,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_nameController.text.characters.length}/$_maximumNameLength',
                    style: const TextStyle(
                      color: Md3Colors.muted,
                      fontSize: 13,
                      height: 1.38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Suggestions',
              style: TextStyle(
                color: Md3Colors.text,
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in _suggestions)
                  _SuggestionChip(
                    text: suggestion,
                    onTap: _submitting
                        ? null
                        : () => _setSuggestedName(suggestion),
                  ),
              ],
            ),
            if (_requestError != null) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Container(
                  key: const Key('create-list-request-error'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Md3Colors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Md3Colors.danger.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: Md3Colors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _requestError!,
                          style: const TextStyle(
                            color: Md3Colors.danger,
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Md3PrimaryButton(
              key: const Key('create-list-submit'),
              text: _requestError == null ? 'Create List' : 'Retry',
              icon: _submitting
                  ? Icons.hourglass_top_rounded
                  : _requestError == null
                      ? Icons.add_rounded
                      : Icons.refresh_rounded,
              height: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 72 : 52,
              onPressed: _canSubmit ? _submit : null,
            ),
            if (_submitting) ...[
              const SizedBox(height: 12),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Md3Colors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _SuggestionChip({
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Use $text',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Md3Colors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Md3Colors.border),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Md3Colors.text,
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
