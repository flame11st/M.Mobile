import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:mmobile/Enums/movie_list_type.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/movies_list_page.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:provider/provider.dart';
import 'Providers/movies_state.dart';

class MoviesListsPage extends StatefulWidget {
  final int initialPageIndex;

  const MoviesListsPage({super.key, required this.initialPageIndex});

  @override
  State<StatefulWidget> createState() {
    return MoviesListsPageState(initialPageIndex);
  }
}

class MoviesListsPageState extends State<MoviesListsPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  final serviceAgent = ServiceAgent();
  final nameController = TextEditingController();
  bool submitButtonActive = false;
  bool showGeneralGuidance = true;
  final storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  int initialPageIndex = 0;

  MoviesListsPageState(this.initialPageIndex);

  @override
  void initState() {
    super.initState();
    tabController = TabController(vsync: this, length: 2);

    nameController.addListener(setSubmitButtonActive);
    loadGuidanceState();
  }

  @override
  void dispose() {
    nameController.dispose();
    tabController.dispose();

    super.dispose();
  }

  void setSubmitButtonActive() {
    setState(() {
      submitButtonActive = nameController.text.isNotEmpty;
    });
  }

  Future<void> loadGuidanceState() async {
    final dismissed =
        await storage.read(key: 'movieListsGeneralGuidanceDismissed');

    if (!mounted) {
      return;
    }

    setState(() {
      showGeneralGuidance = dismissed != 'true';
    });
  }

  Future<void> dismissGeneralGuidance() async {
    await storage.write(
        key: 'movieListsGeneralGuidanceDismissed', value: 'true');

    if (!mounted) {
      return;
    }

    setState(() {
      showGeneralGuidance = false;
    });
  }

  Widget getMovieListWidget(MoviesList moviesList, MovieListType type) {
    final preview = moviesList.listMovies.take(3).toList();

    return Md3Card(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (ctx) => MoviesListPage(moviesList: moviesList))),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            height: 72,
            child: Stack(
              children: [
                if (preview.isEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Md3Colors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Md3Colors.border),
                    ),
                    child: const Center(
                      child: Icon(Icons.playlist_add_rounded,
                          color: Md3Colors.muted),
                    ),
                  ),
                for (var i = 0; i < preview.length; i++)
                  Positioned(
                    left: i * 22,
                    child: Md3MoviePoster(
                      movie: preview[i],
                      width: 44,
                      height: 72,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moviesList.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Md3Colors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${moviesList.listMovies.length} item${moviesList.listMovies.length == 1 ? "" : "s"}",
                  style: const TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Md3Colors.muted),
        ],
      ),
    );
  }

  Widget buildSectionIntro({
    required String eyebrow,
    required String title,
    required String description,
    IconData? icon,
    VoidCallback? onDismiss,
    List<Widget> actions = const [],
  }) {
    return Md3Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xffe8f0fb),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Md3Colors.primary, size: 24),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: Md3Colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: Md3Colors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  ...actions,
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: const Icon(
                Icons.close_rounded,
                color: Md3Colors.muted,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildPersonalEmptyState() {
    return buildSectionIntro(
      eyebrow: 'START HERE',
      title: 'Create your first personal list',
      description:
          'Save your own themed collections for movie nights, favorites, and future plans.',
      icon: Icons.playlist_add_check_circle_rounded,
      actions: [
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Md3Chip(text: 'Favorites', icon: Icons.favorite_outline),
            Md3Chip(text: 'Best Sci-Fi', icon: Icons.rocket_launch_outlined),
            Md3Chip(text: 'Weekend Picks', icon: Icons.event_outlined),
          ],
        ),
        const SizedBox(height: 18),
        Md3PrimaryButton(
          text: 'Create List',
          icon: Icons.playlist_add_rounded,
          onPressed: addNewList,
        ),
      ],
    );
  }

  Widget buildLoadingState(String message) {
    return Md3Card(
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Md3Colors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  addNewList() {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);

    final order = getMaxListOrder(moviesState.personalMoviesLists) + 1;
    nameController.clear();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setSheetState) {
          final name = nameController.text.trim();
          final canCreate = name.isNotEmpty;
          const suggestions = [
            'Favorites',
            'Best Sci-Fi',
            'Weekend Picks',
          ];

          Future<void> createList() async {
            if (_formKey.currentState == null ||
                !_formKey.currentState!.validate()) {
              return;
            }

            final listName = nameController.text.trim();
            moviesState.addMoviesList(listName, order);
            nameController.clear();
            Navigator.of(sheetContext).pop();

            if (userState.userId != null && userState.userId!.isNotEmpty) {
              await serviceAgent.createUserMoviesList(
                  userState.userId!, listName, order);
            }
          }

          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
          final bottomSafeArea = MediaQuery.viewPaddingOf(context).bottom;

          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              decoration: const BoxDecoration(
                color: Md3Colors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  12,
                  24,
                  24 + bottomSafeArea,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Md3Colors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Name a collection you will actually use.',
                                  style: TextStyle(
                                    color: Md3Colors.muted,
                                    fontSize: 14,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () {
                              nameController.clear();
                              Navigator.of(sheetContext).pop();
                            },
                            icon: const Icon(Icons.close_rounded,
                                color: Md3Colors.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        autofocus: true,
                        controller: nameController,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setSheetState(() {}),
                        onFieldSubmitted: (_) => createList(),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';

                          if (trimmed.isEmpty) {
                            return 'Enter a list name';
                          }

                          final normalized = trimmed.toLowerCase();
                          final duplicate =
                              moviesState.personalMoviesLists.any((element) {
                            return element.name.trim().toLowerCase() ==
                                normalized;
                          });

                          return duplicate
                              ? 'A list with this name already exists'
                              : null;
                        },
                        decoration: InputDecoration(
                          labelText: 'List name',
                          hintText: 'Best Sci-Fi',
                          filled: true,
                          fillColor: Md3Colors.background,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                const BorderSide(color: Md3Colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                const BorderSide(color: Md3Colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: Md3Colors.primary, width: 1.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final suggestion in suggestions)
                            Md3Chip(
                              text: suggestion,
                              onTap: () {
                                nameController.text = suggestion;
                                setSheetState(() {});
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Md3PrimaryButton(
                        text: 'Create List',
                        icon: Icons.playlist_add_rounded,
                        onPressed: canCreate ? createList : null,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          foregroundColor: Md3Colors.muted,
                        ),
                        onPressed: () {
                          nameController.clear();
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget buildListsScrollView({
    required List<Widget> children,
    required EdgeInsets padding,
  }) {
    return ListView(
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

  @override
  Widget build(BuildContext context) {
    if (initialPageIndex != 0) {
      tabController.animateTo(initialPageIndex);

      initialPageIndex = 0;
    }

    final moviesState = Provider.of<MoviesState>(context);
    moviesState.externalMoviesLists.sort((a, b) => a.order.compareTo(b.order));
    moviesState.personalMoviesLists.sort((a, b) => a.order.compareTo(b.order));
    final bottomSafeArea = Md3NavigationMetrics.bottomMargin(context);
    final personalBottomPadding = bottomSafeArea + 88;

    final headingRow = AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Md3Colors.text,
      elevation: 0,
      flexibleSpace: const Md3LiquidGlass(
        borderRadius: BorderRadius.zero,
        shadows: [],
        child: SizedBox.expand(),
      ),
      title: TabBar(
        controller: tabController,
        indicatorColor: Md3Colors.primary,
        labelColor: Md3Colors.primary,
        unselectedLabelColor: Md3Colors.muted,
        tabs: const [
          Tab(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(FontAwesome5.empire),
              SizedBox(
                width: 7,
              ),
              Text(
                'General',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          )),
          Tab(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(FontAwesome5.jedi_order),
              SizedBox(
                width: 5,
              ),
              Text(
                'Personal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          )),
        ],
      ),
    );

    return Scaffold(
        backgroundColor: Md3Colors.background,
        appBar: AdManager.bannerVisible && AdManager.bannersReady
            ? AppBar(
                title: Center(
                  child: AdManager.getBannerWidget(AdManager.listsBannerAd),
                ),
                automaticallyImplyLeading: false,
                elevation: 0.7,
              )
            : PreferredSize(
                preferredSize: const Size(0, 0), child: Container()),
        body: Scaffold(
            backgroundColor: Md3Colors.background,
            appBar: headingRow,
            body: Container(
                color: Md3Colors.background,
                child: TabBarView(
                  controller: tabController,
                  children: [
                    buildListsScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                      children: [
                        if (showGeneralGuidance)
                          buildSectionIntro(
                            eyebrow: 'GENERAL',
                            title: 'Curated collections for every mood',
                            description:
                                'Browse MovieDiary team picks, popular titles, and top-rated collections without mixing them into your recommendations.',
                            icon: Icons.grid_view_rounded,
                            onDismiss: dismissGeneralGuidance,
                          ),
                        if (moviesState.externalMoviesLists.isEmpty)
                          buildLoadingState('Loading curated lists...'),
                        if (moviesState.externalMoviesLists.isNotEmpty)
                          for (int i = 0;
                              i < moviesState.externalMoviesLists.length;
                              i++)
                            getMovieListWidget(
                                moviesState.externalMoviesLists[i],
                                MovieListType.external),
                      ],
                    ),
                    Stack(
                      children: [
                        buildListsScrollView(
                          padding: EdgeInsets.fromLTRB(
                            18,
                            12,
                            18,
                            personalBottomPadding,
                          ),
                          children: [
                            if (moviesState.externalMoviesLists.isEmpty)
                              buildLoadingState('Loading your lists...'),
                            if (moviesState.externalMoviesLists.isNotEmpty &&
                                moviesState.personalMoviesLists.isEmpty)
                              buildPersonalEmptyState(),
                            if (moviesState.personalMoviesLists.isNotEmpty)
                              for (int i = 0;
                                  i < moviesState.personalMoviesLists.length;
                                  i++)
                                getMovieListWidget(
                                    moviesState.personalMoviesLists[i],
                                    MovieListType.personal),
                          ],
                        ),
                        Positioned(
                          right: 18,
                          bottom: bottomSafeArea + 16,
                          child: SizedBox(
                            height: 56,
                            width: 56,
                            child: FloatingActionButton(
                              onPressed: addNewList,
                              backgroundColor: Md3Colors.primary,
                              foregroundColor: Colors.white,
                              tooltip: 'Create List',
                              child: const Icon(
                                Icons.add,
                                size: 32,
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ))));
  }
}
