import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';
import 'package:mmobile/Widgets/Shared/MCard.dart';
import 'package:provider/provider.dart';
import 'Premium.dart';
import 'Providers/MoviesState.dart';
import 'Providers/UserState.dart';
import 'Shared/FilterButton.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:fluttericon/font_awesome5_icons.dart';

class MoviesFilter extends StatelessWidget {
  selectDateFrom(BuildContext context, MoviesState state) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: state.dateFrom,
      firstDate: state.dateMin,
      lastDate: state.dateMax,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).accentColorBrightness == Brightness.dark
              ? ThemeData.dark()
              : ThemeData.light(), // This will change to light theme.
          child: child,
        );
      },
    );
    if (picked != null && picked != state.dateFrom)
      state.changeDateFromFilter(picked);
  }

  selectDateTo(BuildContext context, MoviesState state) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: state.dateTo,
      firstDate: state.dateMin,
      lastDate: state.dateMax,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).accentColorBrightness == Brightness.dark
              ? ThemeData.dark()
              : ThemeData.light(), // This will change to light theme.
          child: child,
        );
      },
    );
    if (picked != null && picked != state.dateTo)
      state.changeDateToFilter(picked);
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final isWatchlist = moviesState.isWatchlist();
    final userState = Provider.of<UserState>(context);

    return Container(
        height: isWatchlist ? 250 : 450,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MCard(
                    shadowColor: moviesState.selectedGenre != null
                        ? Theme.of(context).accentColor
                        : Theme.of(context).hintColor,
                    marginTop: 0,
                    padding: 0,
                    child: Container(
                        width: 320,
                        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            DropdownButton(
                              value: moviesState.selectedGenre,
                              hint: Text('Select Genre'),
                              onChanged: ((String value) {
                                moviesState.changeGenreFilter(value);
                              }),
                              items: moviesState.genres,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.clear,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FilterIcon(
                      icon: Icons.favorite_border,
                      text: 'Liked',
                      isActive: moviesState.likedOnly,
                      onPressedCallback: () {
                        moviesState.changeLikedOnlyFilter();
                      }),
                  FilterIcon(
                      icon: FontAwesome5.ban,
                      text: 'Not Liked',
                      isActive: moviesState.notLikedOnly,
                      onPressedCallback: () {
                        moviesState.changeNotLikedOnlyFilter();
                      }),
                ],
              ),
            if (!isWatchlist)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilterIcon(
                    iconColor: userState.isPremium ? null : Colors.green,
                    icon: userState.isPremium
                        ? Icons.calendar_today
                        : Icons.monetization_on,
                    text: "From:  ${DateFormat('yyyy-MM-dd').format(moviesState.dateFrom)}",
                    isActive: moviesState.isDateFromSelected(),
                    onPressedCallback: () {
                      if (userState.isPremium)
                        selectDateFrom(context, moviesState);
                      else
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => Premium()));
                    },
                    textSize: 16,
                  ),
                  FilterIcon(
                    iconColor: userState.isPremium ? null : Colors.green,
                    icon: userState.isPremium
                        ? Icons.calendar_today
                        : Icons.monetization_on,
                    text: "To:    ${DateFormat('yyyy-MM-dd').format(moviesState.dateTo)}",
                    isActive: moviesState.isDateToSelected(),
                    onPressedCallback: () {
                      if (userState.isPremium)
                        selectDateTo(context, moviesState);
                      else
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => Premium()));
                    },
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
                SizedBox(
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
              ],
            )
          ],
        ));
  }
}
