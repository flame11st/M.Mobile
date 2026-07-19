import 'package:flutter/material.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:provider/provider.dart';
import '../movies_lists_page.dart';
import 'm_button.dart';
import 'm_card.dart';
import 'm_snack_bar.dart';

class MAddToListButton extends StatelessWidget {
  final serviceAgent = ServiceAgent();
  final Movie movie;
  final MoviesList? moviesList;
  final bool fromMenu;
  final bannerVisible = AdManager.bannerVisible;

  MAddToListButton(
      {required this.movie, this.moviesList, this.fromMenu = false});

  Widget getMovieListWidget(
      MoviesList list, BuildContext context, BuildContext dialogContext) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    bool movieInList = list.listMovies.any((element) => element.id == movie.id);

    return GestureDetector(
        onTap: () async {
          if (movieInList) return;

          Navigator.of(dialogContext).pop();

          Navigator.of(context).pop();

          if (fromMenu) {
            Navigator.of(context).pop();
          }

          await Future.delayed(const Duration(milliseconds: 300));

          MSnackBar.showSnackBar(
              '"${movie.title}" added to your list "${list.name}"', true);

          if (userState.userId != null && userState.userId!.isNotEmpty) {
            await serviceAgent.addMovieToList(
                userState.userId!, movie.id, list.name);
          }

          moviesState.addMovieToPersonalList(list.name, movie);
        },
        child: MCard(
            color: movieInList
                ? Theme.of(context).cardColor.withOpacity(0.9)
                : Theme.of(context).cardColor,
            padding: 15,
            marginLR: 2,
            marginBottom: 15,
            marginTop: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                        "${list.listMovies.length} item${list.listMovies.length == 1 ? "" : "s"}")
                  ],
                )),
                if (movieInList) const Icon(Icons.check)
              ],
            )));
  }

  void showListsDialog(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context, listen: false);

    var userLists = moviesState.personalMoviesLists;

    userLists.sort((a, b) => a.order.compareTo(b.order));

    showDialog<String>(
        context: context,
        builder: (BuildContext context1) => AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              backgroundColor: Theme.of(context).primaryColor,
              contentTextStyle: Theme.of(context).textTheme.headlineSmall,
              content: SizedBox(
                height: userLists.isEmpty
                    ? 100
                    : (80 * userLists.length + 80).toDouble(),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (userLists.isNotEmpty)
                      Text(
                        'Add to a personal list',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    Expanded(
                        child: ListView(
                      children: [
                        if (userLists.isEmpty)
                          const Text(
                            "You haven't created a personal list yet.\n\n"
                            "Open Lists > Personal to create one.",
                            style: TextStyle(fontSize: 16),
                          ),
                        if (userLists.isEmpty)
                          const SizedBox(
                            height: 10,
                          ),
                        for (int i = 0; i < userLists.length; i++)
                          getMovieListWidget(userLists[i], context, context1),
                      ],
                    )),
                  ],
                ),
              ),
              actions: [
                MButton(
                  width: (MediaQuery.of(context).size.width / 2) - 55,
                  active: true,
                  text: 'Open Lists',
                  onPressedCallback: () {
                    Navigator.of(context).pop();

                    Navigator.of(context1).pop();

                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => const MoviesListsPage(
                              initialPageIndex: 1,
                            )));
                  },
                ),
                const SizedBox(
                  width: 10,
                ),
                MButton(
                  width: (MediaQuery.of(context).size.width / 2) - 55,
                  active: true,
                  text: "Close",
                  parentContext: context,
                  onPressedCallback: () {
                    Navigator.of(context1).pop();
                  },
                ),
              ],
            ));
  }

  removeMovieFromList(BuildContext context) async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);
    final userId = userState.userId;
    final listName = moviesList!.name;

    Navigator.of(context).pop();

    if (fromMenu) {
      Navigator.of(context).pop();
    }

    await Future.delayed(const Duration(milliseconds: 300));

    MSnackBar.showSnackBar(
        '"${movie.title}" removed from your list "$listName"', true);

    moviesState.removeMovieFromPersonalList(listName, movie);

    if (userId != null && userId.isNotEmpty) {
      await serviceAgent.removeMovieFromList(userId, movie.id, listName);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRemove = moviesList != null;
    var text = isRemove ? 'Remove from this List' : 'Add to List';

    return MButton(
      prependIcon: isRemove ? Icons.clear : Icons.add,
      height: 40,
      active: true,
      width: MediaQuery.of(context).size.width - 100,
      text: text,
      onPressedCallback: () async {
        isRemove ? removeMovieFromList(context) : showListsDialog(context);
      },
    );
  }
}
