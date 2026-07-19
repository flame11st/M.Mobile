import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mmobile/Widgets/Shared/m_button.dart';
import 'package:mmobile/Widgets/Shared/m_card.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:provider/provider.dart';
import 'Providers/movies_state.dart';
import 'Shared/filter_button.dart';
import 'Shared/md3_ui.dart';
import 'package:fluttericon/font_awesome_icons.dart';

class MoviesFilter extends StatelessWidget {
  selectDateFrom(BuildContext context, MoviesState state) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: state.dateFrom!,
      firstDate: state.dateMin!,
      lastDate: state.dateMax!,
      builder: (context, child) {
        return Theme(
          // data: Theme.of(context).accentColorBrightness == Brightness.dark
          //     ? ThemeData.dark()
          //     : ThemeData.light(),
          data: ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null && picked != state.dateFrom) {
      state.changeDateFromFilter(picked);
    }
  }

  selectDateTo(BuildContext context, MoviesState state) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: state.dateTo!,
      firstDate: state.dateMin!,
      lastDate: state.dateMax!,
      builder: (context, child) {
        return Theme(
          // data: Theme.of(context).accentColorBrightness == Brightness.dark
          //     ? ThemeData.dark()
          //     : ThemeData.light(),
          data: ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null && picked != state.dateTo) {
      state.changeDateToFilter(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final isWatchlist = moviesState.isWatchlist();
    final heading = isWatchlist ? 'Filter Watchlist' : 'Filter Viewed';
    return Container(
        height: isWatchlist ? 300 : 500,
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: const BorderRadius.all(Radius.circular(40)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text(
              heading,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MCard(
                    shadowColor: moviesState.selectedGenre != null
                        ? Theme.of(context).indicatorColor
                        : Theme.of(context).hintColor,
                    marginTop: 0,
                    padding: 0,
                    child: Container(
                        width: 340,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          color: moviesState.selectedGenre != null
                              ? Theme.of(context).indicatorColor
                              : Theme.of(context).cardColor,
                        ),
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: 250,
                              child: DropdownButton(
                                dropdownColor: moviesState.selectedGenre == null
                                    ? Theme.of(context).cardColor
                                    : Theme.of(context).indicatorColor,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: moviesState.selectedGenre == null
                                        ? Theme.of(context).hintColor
                                        : Theme.of(context).cardColor),
                                isExpanded: true,
                                value: moviesState.selectedGenre,
                                hint: const Text('Select Genre'),
                                onChanged: ((String? value) {
                                  moviesState.changeGenreFilter(value);
                                }),
                                items: moviesState.genres,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: moviesState.selectedGenre == null
                                    ? Theme.of(context)
                                        .hintColor
                                        .withOpacity(0.6)
                                    : Theme.of(context).primaryColor,
                              ),
                              onPressed: moviesState.selectedGenre == null
                                  ? null
                                  : () => moviesState.changeGenreFilter(null),
                            )
                          ],
                        )))
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                FilterIcon(
                  icon: FontAwesome.video,
                  text: 'Movies',
                  isActive: moviesState.moviesOnly,
                  onPressedCallback: () {
                    moviesState.changeMoviesOnlyFilter();
                  },
                ),
                FilterIcon(
                  icon: Icons.tv,
                  text: 'TV shows',
                  isActive: moviesState.tvOnly,
                  onPressedCallback: () {
                    moviesState.changeTVOnlyFilter();
                  },
                ),
              ],
            ),
            if (!isWatchlist)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Opinion',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            if (!isWatchlist)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    Md3Chip(
                      text: 'All',
                      icon: Icons.done_all_rounded,
                      active: moviesState.selectedRates.length == 3,
                      onTap: () => moviesState.selectAllViewedRates(),
                    ),
                    Md3Chip(
                      text: 'Liked',
                      icon: Icons.favorite_rounded,
                      active:
                          moviesState.selectedRates.contains(MovieRate.liked),
                      onTap: () => moviesState.changeLikedOnlyFilter(),
                    ),
                    Md3Chip(
                      text: 'Okay',
                      icon: Icons.sentiment_satisfied_alt_rounded,
                      active:
                          moviesState.selectedRates.contains(MovieRate.okay),
                      onTap: () => moviesState.changeOkayOnlyFilter(),
                    ),
                    Md3Chip(
                      text: 'Disliked',
                      icon: Icons.block_rounded,
                      active: moviesState.selectedRates
                          .contains(MovieRate.notLiked),
                      onTap: () => moviesState.changeNotLikedOnlyFilter(),
                    ),
                  ],
                ),
              ),
            if (!isWatchlist)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Date range',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            if (!isWatchlist)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilterIcon(
                    text:
                        "From:  ${DateFormat('yyyy-MM-dd').format(moviesState.dateFrom != null ? moviesState.dateFrom! : DateTime.now())}",
                    isActive: moviesState.isDateFromSelected(),
                    onPressedCallback: () =>
                        selectDateFrom(context, moviesState),
                    textSize: 16,
                  ),
                  FilterIcon(
                    text:
                        "To:    ${DateFormat('yyyy-MM-dd').format(moviesState.dateTo != null ? moviesState.dateTo! : DateTime.now())}",
                    isActive: moviesState.isDateToSelected(),
                    onPressedCallback: () => selectDateTo(context, moviesState),
                    textSize: 16,
                  ),
                ],
              ),
            Column(
              children: [
                Divider(
                  color: Theme.of(context).hintColor.withOpacity(0.2),
                  height: 5,
                  thickness: 1,
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MButton(
                      active: true,
                      text: 'Close',
                      width: 160,
                      height: 40,
                      onPressedCallback: () => Navigator.of(context).pop(),
                    ),
                    MButton(
                      active: moviesState.isAnyFilterSelected(),
                      text: 'Clear all',
                      width: 160,
                      height: 40,
                      onPressedCallback: () => moviesState.clearAllFilters(),
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
            )
          ],
        ));
  }
}
